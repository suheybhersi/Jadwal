import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jadwal/components/bottom_nav_bar.dart';
import 'package:jadwal/pages/onboarding/new_plan.dart';
import 'package:jadwal/pages/onboarding/onboarding.dart';
import 'package:jadwal/pages/onboarding/usage_mode_selection.dart';
import 'package:jadwal/services/firestore.dart';
import 'package:jadwal/services/user_preferences_service.dart';
import 'package:jadwal/services/tutorial_service.dart';
import 'package:jadwal/pages/onboarding/app_tutorial_page.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Wrapper widget to show tutorial on first app entry
class _TutorialWrapper extends StatefulWidget {
  final Widget child;

  const _TutorialWrapper({required this.child});

  @override
  State<_TutorialWrapper> createState() => _TutorialWrapperState();
}

class _TutorialWrapperState extends State<_TutorialWrapper> {
  bool _hasShownTutorial = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorialIfNeeded();
    });
  }

  void _showTutorialIfNeeded() async {
    if (_hasShownTutorial || !mounted) return;

    final tutorialService = Provider.of<TutorialService>(context, listen: false);
    if (!tutorialService.hasCompletedTutorial) {
      _hasShownTutorial = true;
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AppTutorialPage(),
            fullscreenDialog: true,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

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

              return Consumer<TutorialService>(
                builder: (context, tutorialService, child) {
                  return StreamBuilder(
                    stream: firestoreService.getHifdhsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        // Show tutorial if not completed - use a separate widget to handle navigation
                        if (!tutorialService.hasCompletedTutorial) {
                          return _TutorialWrapper(
                            child: Scaffold(
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
                            ),
                          );
                        }

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
            },
          );
        } else {
          return const OnboardingScreen();
        }
      },
    );
  }
}
