import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jadwal/components/bottom_nav_bar.dart';
import 'package:jadwal/pages/onboarding/finished_memorising_question_page.dart';
import 'package:jadwal/pages/onboarding/new_plan.dart';
import 'package:jadwal/pages/onboarding/onboarding.dart';
import 'package:jadwal/pages/onboarding/usage_mode_selection.dart';
import 'package:jadwal/services/firestore.dart';
import 'package:jadwal/services/tutorial_service.dart';
import 'package:jadwal/services/user_preferences_service.dart';
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

    final tutorialService =
        Provider.of<TutorialService>(context, listen: false);
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

/// Loading screen shown while prefs/tutorial state is loading; avoids flashing mode or tutorial.
class _AuthLoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/app_logo.png',
              width: 160,
              height: 160,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              color: const Color(0xFF4979FB),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// When user has no hifdhs: first ask if they've finished memorising the Quran.
/// If yes, create completed plan and stream updates to home.
/// If no, show plan creation; after plan, mode selection is shown (has hifdhs branch).
class _NoHifdhsRouter extends StatefulWidget {
  final FirestoreService firestoreService;

  const _NoHifdhsRouter({required this.firestoreService});

  @override
  State<_NoHifdhsRouter> createState() => _NoHifdhsRouterState();
}

class _NoHifdhsRouterState extends State<_NoHifdhsRouter> {
  /// question → plan (only if No)
  String _step = 'question';

  @override
  Widget build(BuildContext context) {
    if (_step == 'plan') {
      return const NewPlanScreen();
    }
    return FinishedMemorisingQuestionPage(
      firestoreService: widget.firestoreService,
      onNo: () => setState(() => _step = 'plan'),
    );
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

          return StreamBuilder(
            stream: firestoreService.getHifdhsStream(),
            builder: (context, snapshot) {
              // Wait for stream to emit before deciding; avoids flashing "have you memorised" screen
              if (!snapshot.hasData) {
                return _AuthLoadingScreen();
              }
              if (snapshot.data!.docs.isNotEmpty) {
                return Consumer<UserPreferencesService>(
                  builder: (context, prefsService, child) {
                    // Wait for prefs to load so we don't flash mode selection or tutorial
                    if (!prefsService.initialLoadDone) {
                      return _AuthLoadingScreen();
                    }
                    // After plan creation: show mode selection if not done yet
                    if (!prefsService.hasCompletedModeSelection) {
                      return UsageModeSelectionPage(
                        onComplete: () {
                          (context as Element).markNeedsBuild();
                        },
                      );
                    }

                    return Consumer<TutorialService>(
                      builder: (context, tutorialService, child) {
                        // Wait for tutorial prefs so we don't flash tutorial
                        if (!tutorialService.initialLoadDone) {
                          return _AuthLoadingScreen();
                        }
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
                      },
                    );
                  },
                );
              }
              // Stream has data and docs are empty: user really has no hifdhs
              return _NoHifdhsRouter(
                firestoreService: firestoreService,
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
