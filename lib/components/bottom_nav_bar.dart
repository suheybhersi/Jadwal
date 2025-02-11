import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hifdh_planner_app/pages/screens/home_page.dart';
import 'package:hifdh_planner_app/pages/screens/plan_page.dart';
import 'package:hifdh_planner_app/pages/screens/profile_page.dart';
import 'package:hifdh_planner_app/pages/screens/progress_page.dart';
import 'package:iconsax/iconsax.dart';

class MyBottomNavBar extends StatelessWidget {
  const MyBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigatorController());

    return Scaffold(
      extendBody: false,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return TextStyle(
                    color: const Color.fromARGB(255, 73, 121, 251));
              }
              return TextStyle(color: const Color.fromARGB(255, 127, 131, 141));
            }),
          ),
        ),
        child: Obx(
          () => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
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
                  // height: 65,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  animationDuration: Duration.zero,
                  indicatorColor: Colors.white,
                  backgroundColor: Colors.white,
                  selectedIndex: controller.selectedIndex.value,
                  onDestinationSelected: (value) =>
                      controller.selectedIndex.value = value,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    NavigationDestination(
                      icon: Icon(
                        controller.selectedIndex.value == 0
                            ? Iconsax.home_15
                            : Iconsax.home,
                        color: controller.selectedIndex.value == 0
                            ? const Color.fromARGB(255, 73, 121, 251)
                            : const Color.fromARGB(255, 127, 131, 141),
                        size: 24,
                      ),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(
                        controller.selectedIndex.value == 1
                            ? Iconsax.clipboard_text5
                            : Iconsax.clipboard_text,
                        color: controller.selectedIndex.value == 1
                            ? const Color.fromARGB(255, 73, 121, 251)
                            : const Color.fromARGB(255, 127, 131, 141),
                        size: 24,
                      ),
                      label: 'Plan',
                    ),
                    NavigationDestination(
                      icon: Icon(
                        controller.selectedIndex.value == 2
                            ? Iconsax.status_up5
                            : Iconsax.status_up,
                        color: controller.selectedIndex.value == 2
                            ? const Color.fromARGB(255, 73, 121, 251)
                            : const Color.fromARGB(255, 127, 131, 141),
                        size: 24,
                      ),
                      label: 'Progress',
                    ),
                    NavigationDestination(
                      icon: Icon(
                        controller.selectedIndex.value == 3
                            ? Iconsax.profile_circle5
                            : Iconsax.profile_circle,
                        color: controller.selectedIndex.value == 3
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
      ),
      body: Obx(() => controller.screens[controller.selectedIndex.value]),
    );
  }
}

class NavigatorController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;

  final screens = [
    HomePage(),
    PlanPage(),
    ProgressPage(),
    ProfilePage(),
  ];
}
