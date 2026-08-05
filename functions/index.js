const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { defineSecret } = require('firebase-functions/params');
const axios = require('axios');
const FormData = require('form-data');

admin.initializeApp();

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
  const snap = await admin.firestore().collection('users').doc(uid).get();
  if (!snap.exists || snap.data().isPro !== true) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Jadwal Pro is required for this feature.'
    );
  }
}

/**
 * Proxy function to generate wrong options for fill-in-the-blank questions.
 * The API key never leaves the server.
 */
exports.generateWrongOptions = functions
  .runWith({ secrets: [openaiApiKey] })
  .https.onCall(async (data, context) => {
    verifyAuth(context);
    await requirePro(context.auth.uid);

    const { correctWord, context: verseContext, numberOfOptions } = data;

    if (!correctWord || !verseContext || !numberOfOptions) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required parameters: correctWord, context, numberOfOptions'
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

      const prompt = `
Generate ${numberOfOptions} Arabic words that could plausibly fit in the blank but would be incorrect in the following context. 
The words should be challenging distractors for someone who knows Arabic but doesn't know the exact answer.
The correct word is: "${correctWord}"
The context is: "${verseContext}"

Rules:
1. Only provide words that would grammatically fit but are semantically incorrect
2. The words should be of similar length, style, and difficulty as the correct word
3. Return a JSON object with the correct word as the key and an array of wrong options as the value
4. Each word should be a single Arabic word, not a phrase
5. Do not include the correct word in your response

Example response format:
{
  "${correctWord}": ["wrong1", "wrong2", "wrong3", "wrong4", "wrong5"]
}
`;

      const response = await axios.post(
        'https://api.openai.com/v1/chat/completions',
        {
          model: 'gpt-3.5-turbo',
          messages: [
            {
              role: 'system',
              content:
                'You are a helpful assistant that generates plausible but incorrect Arabic words for fill-in-the-blank questions.'
            },
            { role: 'user', content: prompt }
          ],
          temperature: 0.7,
          max_tokens: 150,
          response_format: { type: 'json_object' }
        },
        {
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${apiKey}`
          }
        }
      );

      if (response.status === 200) {
        const content = response.data.choices[0].message.content;
        const jsonContent = JSON.parse(content);

        // Extract the wrong options
        if (jsonContent[correctWord] && Array.isArray(jsonContent[correctWord])) {
          return { wrongOptions: jsonContent[correctWord] };
        } else if (Object.values(jsonContent)[0] && Array.isArray(Object.values(jsonContent)[0])) {
          return { wrongOptions: Object.values(jsonContent)[0] };
        } else if (jsonContent.words && Array.isArray(jsonContent.words)) {
          return { wrongOptions: jsonContent.words };
        } else {
          throw new functions.https.HttpsError(
            'internal',
            'Unexpected response format from OpenAI'
          );
        }
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
      throw new functions.https.HttpsError(
        'internal',
        `Failed to generate wrong options: ${error.message}`
      );
    }
  });

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

    if (!audioBase64) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required parameter: audioBase64'
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
        filename: filename || 'recording.wav',
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
          maxContentLength: Infinity,
          maxBodyLength: Infinity
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
      throw new functions.https.HttpsError(
        'internal',
        `Failed to convert speech to text: ${error.message}`
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

    if (!expected || provided !== expected) {
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
      await admin.firestore().collection('users').doc(appUserId).set(
        {
          isPro,
          proUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
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

      await admin.firestore().collection('users').doc(uid).set(
        {
          isPro,
          proUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
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

