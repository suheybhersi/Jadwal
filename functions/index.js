const functions = require('firebase-functions/v1');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { defineSecret } = require('firebase-functions/params');
const axios = require('axios');
const FormData = require('form-data');
const crypto = require('crypto');

initializeApp();

// Largest audio upload accepted (OpenAI's own limit is 25 MB).
const MAX_AUDIO_BYTES = 10 * 1024 * 1024;

/** Compare two strings in constant time so the secret can't be guessed by timing. */
function secretsMatch(provided, expected) {
  const a = crypto.createHash('sha256').update(String(provided)).digest();
  const b = crypto.createHash('sha256').update(String(expected)).digest();
  return crypto.timingSafeEqual(a, b);
}

// Define the secrets
const openaiApiKey = defineSecret('OPENAI_API_KEY');
const revenueCatWebhookSecret = defineSecret('REVENUECAT_WEBHOOK_SECRET');
const revenueCatSecretApiKey = defineSecret('REVENUECAT_SECRET_API_KEY');

// Common function to verify authentication
function verifyAuth(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }
}

/** Require users/{uid}.isPro === true (set by RevenueCat webhook). */
async function requirePro(uid) {
  const snap = await getFirestore().collection('users').doc(uid).get();
  if (!snap.exists || snap.data().isPro !== true) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Jadwal Pro is required for this feature.'
    );
  }
}

/**
 * Proxy function to convert speech to text using Whisper API.
 * The API key never leaves the server.
 */
exports.convertSpeechToText = functions
  .runWith({ secrets: [openaiApiKey] })
  .https.onCall(async (data, context) => {
    verifyAuth(context);
    await requirePro(context.auth.uid);

    const { audioBase64, filename } = data;

    if (!audioBase64 || typeof audioBase64 !== 'string') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required parameter: audioBase64'
      );
    }

    // Base64 is ~4/3 the size of the raw audio.
    if (audioBase64.length * 0.75 > MAX_AUDIO_BYTES) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Recording is too large.'
      );
    }

    try {
      const apiKey = openaiApiKey.value();
      if (!apiKey) {
        throw new functions.https.HttpsError(
          'internal',
          'API key is not configured.'
        );
      }

      // Convert base64 to buffer
      const audioBuffer = Buffer.from(audioBase64, 'base64');

      // Create form data
      const formData = new FormData();
      formData.append('file', audioBuffer, {
        filename: typeof filename === 'string' && filename ? filename : 'recording.wav',
        contentType: 'audio/wav'
      });
      formData.append('model', 'whisper-1');
      formData.append('language', 'ar');

      const response = await axios.post(
        'https://api.openai.com/v1/audio/transcriptions',
        formData,
        {
          headers: {
            ...formData.getHeaders(),
            'Authorization': `Bearer ${apiKey}`
          },
          maxContentLength: 1024 * 1024,
          maxBodyLength: MAX_AUDIO_BYTES * 2,
          timeout: 60000
        }
      );

      if (response.status === 200) {
        return { text: response.data.text || '' };
      } else {
        throw new functions.https.HttpsError(
          'internal',
          `OpenAI API error: ${response.status}`
        );
      }
    } catch (error) {
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      console.error('convertSpeechToText error', error.response?.data || error.message);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to convert speech to text.'
      );
    }
  });

/**
 * RevenueCat webhook → sync users/{uid}.isPro
 * Configure Authorization header in RevenueCat to match REVENUECAT_WEBHOOK_SECRET.
 */
exports.revenueCatWebhook = functions
  .runWith({ secrets: [revenueCatWebhookSecret] })
  .https.onRequest(async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    const expected = revenueCatWebhookSecret.value();
    const authHeader = req.get('Authorization') || '';
    const provided = authHeader.startsWith('Bearer ')
      ? authHeader.slice(7)
      : authHeader;

    if (!expected || !secretsMatch(provided, expected)) {
      res.status(401).send('Unauthorized');
      return;
    }

    const event = req.body && req.body.event ? req.body.event : req.body;
    if (!event || !event.type) {
      res.status(400).send('Bad Request');
      return;
    }

    const appUserId = event.app_user_id || event.original_app_user_id;
    if (!appUserId || typeof appUserId !== 'string') {
      // Anonymous / missing — acknowledge to avoid retries
      res.status(200).send('ok');
      return;
    }

    // Ignore RevenueCat anonymous IDs that aren't Firebase uids
    if (appUserId.startsWith('$RCAnonymousID:')) {
      res.status(200).send('ok');
      return;
    }

    const activateTypes = new Set([
      'INITIAL_PURCHASE',
      'RENEWAL',
      'UNCANCELLATION',
      'PRODUCT_CHANGE',
      'NON_RENEWING_PURCHASE',
      'SUBSCRIPTION_EXTENDED',
      'TEMPORARY_ENTITLEMENT_GRANT'
    ]);
    const deactivateTypes = new Set([
      'EXPIRATION',
      'REFUND',
      'REVOKE'
    ]);

    let isPro = null;
    if (activateTypes.has(event.type)) {
      isPro = true;
    } else if (deactivateTypes.has(event.type)) {
      isPro = false;
    } else {
      res.status(200).send('ignored');
      return;
    }

    try {
      await getFirestore().collection('users').doc(appUserId).set(
        {
          isPro,
          proUpdatedAt: FieldValue.serverTimestamp(),
          revenueCatLastEvent: event.type
        },
        { merge: true }
      );
      res.status(200).send('ok');
    } catch (error) {
      console.error('revenueCatWebhook error', error);
      res.status(500).send('error');
    }
  });

/**
 * Pull entitlement state from RevenueCat REST API into Firestore.
 * Call after purchase/restore so AI gates work before the webhook arrives.
 */
exports.syncProEntitlement = functions
  .runWith({ secrets: [revenueCatSecretApiKey] })
  .https.onCall(async (data, context) => {
    verifyAuth(context);
    const uid = context.auth.uid;
    const secret = revenueCatSecretApiKey.value();
    if (!secret) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'RevenueCat secret API key is not configured.'
      );
    }

    try {
      const response = await axios.get(
        `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(uid)}`,
        {
          headers: {
            Authorization: `Bearer ${secret}`,
            'Content-Type': 'application/json'
          }
        }
      );

      const entitlements =
        (response.data &&
          response.data.subscriber &&
          response.data.subscriber.entitlements) ||
        {};
      const pro = entitlements.pro;
      const isPro = !!(pro && (!pro.expires_date || new Date(pro.expires_date) > new Date()));

      await getFirestore().collection('users').doc(uid).set(
        {
          isPro,
          proUpdatedAt: FieldValue.serverTimestamp(),
          revenueCatLastEvent: 'SYNC'
        },
        { merge: true }
      );

      return { isPro };
    } catch (error) {
      console.error('syncProEntitlement error', error.response?.data || error.message);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to sync subscription status.'
      );
    }
  });

