import 'package:cloud_firestore/cloud_firestore.dart';

class LoginActivity {
  final String id;
  final DateTime timestamp;
  final String device;
  final String platform;
  final String? osVersion;
  final String method;

  const LoginActivity({
    required this.id,
    required this.timestamp,
    required this.device,
    required this.platform,
    this.osVersion,
    required this.method,
  });

  factory LoginActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawTimestamp = data['timestamp'];
    DateTime timestamp;
    if (rawTimestamp is Timestamp) {
      timestamp = rawTimestamp.toDate();
    } else if (rawTimestamp is DateTime) {
      timestamp = rawTimestamp;
    } else {
      timestamp = DateTime.now();
    }

    return LoginActivity(
      id: doc.id,
      timestamp: timestamp,
      device: data['device'] as String? ?? 'Unknown device',
      platform: data['platform'] as String? ?? 'Unknown',
      osVersion: data['osVersion'] as String?,
      method: data['method'] as String? ?? 'email',
    );
  }

  String get methodLabel {
    switch (method) {
      case 'registration':
        return 'Account created';
      case 'email':
        return 'Signed in with email';
      default:
        return 'Signed in';
    }
  }

  bool get isRegistration => method == 'registration';
}
