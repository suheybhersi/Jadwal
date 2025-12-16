const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { defineSecret } = require('firebase-functions/params');
const axios = require('axios');
const FormData = require('form-data');

admin.initializeApp();

// Define the secret
const openaiApiKey = defineSecret('OPENAI_API_KEY');

// Common function to verify authentication
function verifyAuth(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
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

