import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  static String? get apiKey => dotenv.env['API_KEY'];

  /// Generates challenging wrong options for a fill-in-the-blank question
  ///
  /// [correctWord] is the correct answer
  /// [context] is the verse or sentence context
  /// [numberOfOptions] is how many wrong options to generate
  static Future<List<String>> generateWrongOptions({
    required String correctWord,
    required String context,
    required int numberOfOptions,
  }) async {
    try {
      // Validate API key exists
      if (apiKey == null || apiKey!.isEmpty) {
        throw Exception(
            'OpenAI API key is missing. Please check your environment variables.');
      }

      final url = Uri.https('api.openai.com', 'v1/chat/completions');

      final prompt = '''
Generate $numberOfOptions Arabic words that could plausibly fit in the blank but would be incorrect in the following context. 
The words should be challenging distractors for someone who knows Arabic but doesn't know the exact answer.
The correct word is: "$correctWord"
The context is: "$context"

Rules:
1. Only provide words that would grammatically fit but are semantically incorrect
2. The words should be of similar length, style, and difficulty as the correct word
3. Return a JSON object with the correct word as the key and an array of wrong options as the value
4. Each word should be a single Arabic word, not a phrase
5. Do not include the correct word in your response

Example response format:
{
  "$correctWord": ["wrong1", "wrong2", "wrong3", "wrong4", "wrong5"]
}
''';

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a helpful assistant that generates plausible but incorrect Arabic words for fill-in-the-blank questions.'
            },
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'max_tokens': 150,
          'response_format': {'type': 'json_object'}
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        final content = jsonResponse['choices'][0]['message']['content'];

        try {
          // Parse the JSON from the content
          final jsonContent = jsonDecode(content);

          // Check if the response has the correct word as a key
          if (jsonContent is Map && jsonContent.containsKey(correctWord)) {
            return List<String>.from(jsonContent[correctWord]);
          } else if (jsonContent is Map && jsonContent.values.isNotEmpty) {
            // If the key doesn't match exactly but we have some values, use the first array
            final firstKey = jsonContent.keys.first;
            return List<String>.from(jsonContent[firstKey]);
          } else if (jsonContent is Map && jsonContent.containsKey('words')) {
            // Fallback for old format
            return List<String>.from(jsonContent['words']);
          } else if (jsonContent is List) {
            // Fallback for array format
            return List<String>.from(jsonContent);
          } else {
            throw Exception('Unexpected response format from OpenAI');
          }
        } catch (parseError) {
          throw Exception('Failed to parse OpenAI response: $parseError');
        }
      } else {
        throw Exception(
            'Failed to get response from OpenAI: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      return [];
    }
  }
}
