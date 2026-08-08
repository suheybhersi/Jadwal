import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jadwal/pages/screens/HomePage/home_page.dart';
import 'package:jadwal/pages/screens/PlanPage/plan_page.dart';
import 'package:jadwal/pages/screens/ProfilePage/profile_page.dart';
import 'package:jadwal/pages/screens/MushafPage/mushaf_page.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_home_page.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/components/network_status_banner.dart';
import 'package:jadwal/services/firestore.dart';

enum _NavTab { home, quran, quiz, plan, profile }

class MyBottomNavBar extends StatefulWidget {
  const MyBottomNavBar({super.key});

  @override
  State<MyBottomNavBar> createState() => _MyBottomNavBarState();
}

class _MyBottomNavBarState extends State<MyBottomNavBar> {
  _NavTab _selectedTab = _NavTab.home;

  final FirestoreService _firestoreService = FirestoreService(
    auth: FirebaseAuth.instance,
    uid: FirebaseAuth.instance.currentUser!.uid,
  );

  List<_NavTab> _tabsFor({required bool showPlan}) => [
        _NavTab.home,
        _NavTab.quran,
        _NavTab.quiz,
        if (showPlan) _NavTab.plan,
        _NavTab.profile,
      ];

  Widget _screenFor(_NavTab tab) {
    switch (tab) {
      case _NavTab.home:
        return const HomePage();
      case _NavTab.quran:
        return const MushafPage();
      case _NavTab.quiz:
        return const QuizHomePage();
      case _NavTab.plan:
        return const PlanPage();
      case _NavTab.profile:
        return ProfilePage();
    }
  }

  NavigationDestination _destinationFor(_NavTab tab, bool selected) {
    const selectedColor = Color.fromARGB(255, 73, 121, 251);
    const unselectedColor = Color.fromARGB(255, 127, 131, 141);
    final color = selected ? selectedColor : unselectedColor;

    switch (tab) {
      case _NavTab.home:
        return NavigationDestination(
          icon: Icon(
            selected ? Iconsax.home_15 : Iconsax.home,
            color: color,
            size: 24,
          ),
          label: 'Home',
        );
      case _NavTab.quran:
        return NavigationDestination(
          icon: Icon(Iconsax.book, color: color, size: 24),
          label: 'Quran',
        );
      case _NavTab.quiz:
        return NavigationDestination(
          icon: Icon(
            selected ? Iconsax.message_question5 : Iconsax.message_question,
            color: color,
            size: 24,
          ),
          label: 'Quiz',
        );
      case _NavTab.plan:
        return NavigationDestination(
          icon: Icon(
            selected ? Iconsax.calendar_tick5 : Iconsax.calendar_tick,
            color: color,
            size: 24,
          ),
          label: 'Plan',
        );
      case _NavTab.profile:
        return NavigationDestination(
          icon: Icon(
            selected ? Iconsax.profile_circle5 : Iconsax.profile_circle,
            color: color,
            size: 26,
          ),
          label: 'Profile',
        );
    }
  }

  bool _isPlanCompleted(QuerySnapshot? snapshot) {
    if (snapshot == null || snapshot.docs.isEmpty) return false;
    final data = snapshot.docs.first.data();
    if (data is! Map<String, dynamic>) return false;
    return data['planCompleted'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getPlansStream(),
      builder: (context, snapshot) {
        final showPlan = !_isPlanCompleted(snapshot.data);
        final tabs = _tabsFor(showPlan: showPlan);

        // If Plan was removed while selected, fall back to Home.
        final selectedTab =
            tabs.contains(_selectedTab) ? _selectedTab : _NavTab.home;
        if (selectedTab != _selectedTab) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedTab = selectedTab);
          });
        }

        final selectedIndex = tabs.indexOf(selectedTab);

        return Scaffold(
          extendBody: false,
          bottomNavigationBar: Theme(
            data: Theme.of(context).copyWith(
              navigationBarTheme: NavigationBarThemeData(
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const TextStyle(
                      color: Color.fromARGB(255, 73, 121, 251),
                      fontWeight: FontWeight.w500,
                    );
                  }
                  return const TextStyle(
                    color: Color.fromARGB(255, 127, 131, 141),
                    fontWeight: FontWeight.w500,
                  );
                }),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .tertiary
                          .withValues(alpha: 0.5),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: NavigationBar(
                    height: 65,
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    animationDuration: Duration.zero,
                    indicatorColor: Theme.of(context).colorScheme.surface,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.9),
                    selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                    onDestinationSelected: (value) {
                      setState(() {
                        _selectedTab = tabs[value];
                      });
                    },
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: [
                      for (final tab in tabs)
                        _destinationFor(tab, tab == selectedTab),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              const NetworkStatusBanner(),
              Expanded(child: _screenFor(selectedTab)),
            ],
          ),
        );
      },
    );
  }
}
