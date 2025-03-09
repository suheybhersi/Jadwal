import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jadwal/services/connectivity_service.dart';
import 'package:jadwal/services/firestore.dart';

class NetworkStatusBanner extends StatelessWidget {
  const NetworkStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivityService = Provider.of<ConnectivityService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);

    // Only show banner if offline
    if (connectivityService.isConnected && !firestoreService.isOfflineMode) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: Colors.orange,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              firestoreService.isOfflineMode
                  ? 'You are offline. Some features may be limited.'
                  : 'No internet connection. Working in offline mode.',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              // Show more detailed information in a dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Network Status'),
                  content: const Text(
                    'Your app is currently in offline mode. This means:\n\n'
                    '• You can view previously loaded data\n'
                    '• New changes will be saved locally\n'
                    '• Data will sync when you reconnect\n\n'
                    'To resolve this issue:\n'
                    '• Check your internet connection\n'
                    '• Ensure you have proper permissions\n'
                    '• Restart the app if the problem persists',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            child:
                const Text('MORE INFO', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
