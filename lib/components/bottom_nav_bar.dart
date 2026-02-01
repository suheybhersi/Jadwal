import 'package:flutter/material.dart';
import 'package:jadwal/pages/screens/HomePage/home_page.dart';
import 'package:jadwal/pages/screens/PlanPage/plan_page.dart';
import 'package:jadwal/pages/screens/ProfilePage/profile_page.dart';
import 'package:jadwal/pages/screens/MushafPage/mushaf_page.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_home_page.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/components/network_status_banner.dart';

class MyBottomNavBar extends StatefulWidget {
  const MyBottomNavBar({super.key});

  @override
  State<MyBottomNavBar> createState() => _MyBottomNavBarState();
}

class _MyBottomNavBarState extends State<MyBottomNavBar> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomePage(),
    MushafPage(),
    QuizHomePage(),
    PlanPage(),
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
            margin: EdgeInsets.only(bottom: 20),
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
                      Iconsax.book,
                      color: _selectedIndex == 1
                          ? const Color.fromARGB(255, 73, 121, 251)
                          : const Color.fromARGB(255, 127, 131, 141),
                      size: 24,
                    ),
                    label: 'Quran',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      _selectedIndex == 2
                          ? Iconsax.message_question5
                          : Iconsax.message_question,
                      color: _selectedIndex == 2
                          ? const Color.fromARGB(255, 73, 121, 251)
                          : const Color.fromARGB(255, 127, 131, 141),
                      size: 24,
                    ),
                    label: 'Quiz',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      _selectedIndex == 3
                          ? Iconsax.calendar_tick5
                          : Iconsax.calendar_tick,
                      color: _selectedIndex == 3
                          ? const Color.fromARGB(255, 73, 121, 251)
                          : const Color.fromARGB(255, 127, 131, 141),
                      size: 24,
                    ),
                    label: 'Plan',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      _selectedIndex == 4
                          ? Iconsax.profile_circle5
                          : Iconsax.profile_circle,
                      color: _selectedIndex == 4
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
      body: Column(
        children: [
          // Network status banner will appear at the top when offline
          const NetworkStatusBanner(),
          // Expanded to fill the remaining space with the selected screen
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}
