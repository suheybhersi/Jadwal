import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jadwal/pages/auth/login_or_register_page.dart';
import 'package:iconsax/iconsax.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnBoardingController());

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: controller.pageController,
            onPageChanged: controller.updatePageIndicator,
            children: [
              OnBoardingPage(
                image: 'assets/app_logo.png',
                title: 'Welcome to Jadwal',
                subTitle: 'Your personal Quran Planner',
              ),
            ],
          ),
          Positioned(
            top: kToolbarHeight - 20,
            right: 5,
            child: TextButton(
              onPressed: () => OnBoardingController.instance.skipPage(),
              child: Text(
                'Skip',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: kBottomNavigationBarHeight - 20,
            right: 16,
            child: ElevatedButton(
              onPressed: () => OnBoardingController.instance.nextPage(),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(15),
                shape: CircleBorder(),
                backgroundColor: const Color.fromARGB(255, 53, 124, 255),
              ),
              child: Icon(
                Iconsax.arrow_right_3,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class OnBoardingPage extends StatelessWidget {
  const OnBoardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.subTitle,
  });

  final String image, title, subTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Image(
          width: 300,
          height: 300,
          image: AssetImage(image),
        ),
        Column(
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(
              height: 8,
            ),
            Text(
              subTitle,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                letterSpacing: 0.5,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class OnBoardingController extends GetxController {
  static OnBoardingController get instance => Get.find();

  final pageController = PageController();
  Rx<int> currentPageIndex = 0.obs;

  void updatePageIndicator(index) => currentPageIndex.value = index;

  void nextPage() {
    if (currentPageIndex.value == 0) {
      Get.to(() => LoginOrRegisterPage());
    } else {
      int page = currentPageIndex.value + 1;
      pageController.jumpToPage(page);
    }
  }

  void skipPage() {
    currentPageIndex.value = 0;
    // pageController.jumpToPage(2);
    Get.to(() => LoginOrRegisterPage());
  }
}
