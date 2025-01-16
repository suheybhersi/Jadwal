import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hifdh_planner_app/components/bottom_nav_bar.dart';
import 'package:hifdh_planner_app/pages/onboarding/new_plan.dart';
import 'package:hifdh_planner_app/pages/onboarding/onboarding.dart';
import 'package:hifdh_planner_app/services/firestore.dart';
import 'package:flutter/services.dart';

class AuthPage extends StatelessWidget {
  AuthPage({super.key}) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final FirestoreService firestoreService =
                  FirestoreService(FirebaseAuth.instance);
              return StreamBuilder(
                stream: firestoreService.getPlansStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    return const Scaffold(
                      bottomNavigationBar: MyBottomNavBar(),
                    );
                  } else {
                    return const NewPlanScreen();
                  }
                },
              );
            } else {
              return const OnboardingScreen();
            }
          },
        ),
      ),
    );
  }
}
