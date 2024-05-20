import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hifdh_planner_app/pages/home_page.dart';
import 'package:hifdh_planner_app/pages/plans_page.dart';
import 'package:hifdh_planner_app/pages/progress_page.dart';
import 'package:hifdh_planner_app/pages/schedule_page.dart';
import 'package:iconsax/iconsax.dart';

class MyBottomNavBar extends StatelessWidget {
  const MyBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigatorController());

    return Scaffold(
      bottomNavigationBar: Obx(
        () => NavigationBar(
          height: 60,
          elevation: 0,
          indicatorColor: Theme.of(context).colorScheme.tertiary,
          backgroundColor: Colors.transparent,
          selectedIndex: controller.selectedIndex.value,
          onDestinationSelected: (value) =>
              controller.selectedIndex.value = value,
          destinations: const [
            Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: NavigationDestination(
                icon: Icon(
                  Iconsax.home,
                  size: 30,
                ),
                label: 'Home',
              ),
            ),
            Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: NavigationDestination(
                  icon: Icon(
                    Iconsax.note,
                    size: 30,
                  ),
                  label: 'Plans',
                )),
            Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: NavigationDestination(
                  icon: ImageIcon(AssetImage('assets/rise.png'), size: 30),
                  label: 'Progress',
                )),
            Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: NavigationDestination(
                  icon: Icon(
                    Iconsax.calendar,
                    size: 30,
                  ),
                  label: 'Schedule',
                )),
          ],
        ),
      ),
      body: Obx(() => controller.screens[controller.selectedIndex.value]),
    );
  }
}

class NavigatorController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;

  final screens = [
    Padding(
      padding: const EdgeInsets.only(top: 50.0),
      child: HomePage(),
    ),
    const Padding(
      padding: EdgeInsets.only(top: 50.0),
      child: PlansPage(),
    ),
    const Padding(
      padding: EdgeInsets.only(top: 50.0),
      child: ProgressPage(),
    ),
    const Padding(
      padding: EdgeInsets.only(top: 50.0),
      child: SchedulePage(),
    ),
  ];
}
