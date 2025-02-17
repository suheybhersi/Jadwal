import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hifdh_planner_app/pages/screens/home_page.dart';
import 'package:hifdh_planner_app/pages/screens/plan_page.dart';
import 'package:hifdh_planner_app/pages/screens/profile_page.dart';
import 'package:hifdh_planner_app/pages/screens/progress_page.dart';
import 'package:iconsax/iconsax.dart';

class MyBottomNavBar extends StatefulWidget {
  const MyBottomNavBar({super.key});

  @override
  State<MyBottomNavBar> createState() => _MyBottomNavBarState();
}

class _MyBottomNavBarState extends State<MyBottomNavBar> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomePage(),
    PlanPage(),
    ProgressPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                    color: Color.fromARGB(255, 73, 121, 251));
              }
              return const TextStyle(color: Color.fromARGB(255, 127, 131, 141));
            }),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            margin: EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).colorScheme.surface,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  spreadRadius: -1,
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
                indicatorColor: Colors.white,
                backgroundColor: Colors.white,
                selectedIndex: _selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    _selectedIndex = value;
                  });
                },
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  NavigationDestination(
                    icon: Icon(
                      _selectedIndex == 0 ? Iconsax.home_15 : Iconsax.home,
                      color: _selectedIndex == 0
                          ? const Color.fromARGB(255, 73, 121, 251)
                          : const Color.fromARGB(255, 127, 131, 141),
                      size: 24,
                    ),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      _selectedIndex == 1
                          ? Iconsax.clipboard_text5
                          : Iconsax.clipboard_text,
                      color: _selectedIndex == 1
                          ? const Color.fromARGB(255, 73, 121, 251)
                          : const Color.fromARGB(255, 127, 131, 141),
                      size: 24,
                    ),
                    label: 'Plan',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      _selectedIndex == 2
                          ? Iconsax.status_up5
                          : Iconsax.status_up,
                      color: _selectedIndex == 2
                          ? const Color.fromARGB(255, 73, 121, 251)
                          : const Color.fromARGB(255, 127, 131, 141),
                      size: 24,
                    ),
                    label: 'Progress',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      _selectedIndex == 3
                          ? Iconsax.profile_circle5
                          : Iconsax.profile_circle,
                      color: _selectedIndex == 3
                          ? const Color.fromARGB(255, 73, 121, 251)
                          : const Color.fromARGB(255, 127, 131, 141),
                      size: 26,
                    ),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: Platform.isIOS
            ? EdgeInsets.zero
            : EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: _screens[_selectedIndex],
      ),
    );
  }
}
