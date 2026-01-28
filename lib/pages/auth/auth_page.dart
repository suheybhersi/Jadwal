import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jadwal/components/bottom_nav_bar.dart';
import 'package:jadwal/pages/onboarding/new_plan.dart';
import 'package:jadwal/pages/onboarding/onboarding.dart';
import 'package:jadwal/pages/onboarding/usage_mode_selection.dart';
import 'package:jadwal/services/firestore.dart';
import 'package:jadwal/services/user_preferences_service.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AuthPage extends StatelessWidget {
  AuthPage({super.key}) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final FirestoreService firestoreService = FirestoreService(
            auth: FirebaseAuth.instance,
            uid: FirebaseAuth.instance.currentUser!.uid,
          );

          // Update user activity and check achievements when user logs in
          WidgetsBinding.instance.addPostFrameCallback((_) {
            firestoreService.updateUserAchievements();
          });

          return Consumer<UserPreferencesService>(
            builder: (context, prefsService, child) {
              // Check if user has completed mode selection
              // Show mode selection for ALL users who haven't selected yet
              if (!prefsService.hasCompletedModeSelection) {
                return UsageModeSelectionPage(
                  onComplete: () {
                    // Force rebuild after mode selection
                    (context as Element).markNeedsBuild();
                  },
                );
              }

              return StreamBuilder(
                stream: firestoreService.getHifdhsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    return Scaffold(
                      body: Padding(
                        padding: EdgeInsets.only(
                          top: Platform.isIOS
                              ? MediaQuery.of(context).padding.top - 10
                              : MediaQuery.of(context).padding.top,
                          bottom: 5,
                        ),
                        child: MediaQuery.removePadding(
                          context: context,
                          removeTop: true,
                          removeBottom: true,
                          child: const MyBottomNavBar(),
                        ),
                      ),
                    );
                  } else {
                    return const NewPlanScreen();
                  }
                },
              );
            },
          );
        } else {
          return const OnboardingScreen();
        }
      },
    );
  }
}
