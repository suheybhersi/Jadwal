import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shown when a Firestore [StreamBuilder] or [FutureBuilder] reports an error.
class FirestoreErrorView extends StatelessWidget {
  final String message;

  const FirestoreErrorView({
    super.key,
    this.message =
        'Unable to load data. Check your connection and try again.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
