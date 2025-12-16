import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to interact with OpenAI through secure Firebase Functions proxies.
/// The API key never leaves the server - all calls are proxied through Firebase Functions.
class OpenAIService {
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
      // Verify user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to use OpenAI features');
      }

      // Call the Firebase Function proxy (API key stays on server)
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('generateWrongOptions');

      final result = await callable.call({
        'correctWord': correctWord,
        'context': context,
        'numberOfOptions': numberOfOptions,
      });

      // Extract wrong options from response
      final wrongOptions = result.data['wrongOptions'] as List?;
      if (wrongOptions != null) {
        return wrongOptions.map((e) => e.toString()).toList();
      }

      return [];
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Failed to generate wrong options: ${e.message}');
    } catch (e) {
      return [];
    }
  }
}
