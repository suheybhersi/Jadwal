import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hifdh_planner_app/components/bottom_nav_bar.dart';
import 'package:hifdh_planner_app/components/drop_down.dart';
import 'package:hifdh_planner_app/components/verse_picker.dart';
import 'package:hifdh_planner_app/services/firestore.dart';

class NewPlanScreen extends StatelessWidget {
  const NewPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NewPlanController());
    final FirestoreService firestoreService =
        FirestoreService(FirebaseAuth.instance);

    void storeNewPlan() {
      //form key surah should be the surah number and verse should be the verse number

      String fromKey =
          '${controller.selectedFromSurahData.value?['surahNumber']}:${controller.selectedFromVerse.value}';
      String toKey =
          '${controller.selectedToSurahData.value?['surahNumber']}:${controller.selectedToVerse.value}';
      int lines = controller.selectedUnit.value == 'Lines'
          ? int.parse(controller.inputController.text)
          : int.parse(controller.inputController.text) * 15;

      firestoreService.addPlan(
          fromKey, toKey, lines, controller.selectedDays.toList());
    }

    return Scaffold(
      appBar: AppBar(
        leading: Obx(() => controller.currentPageIndex.value != 0
            ? IconButton(
                onPressed: () => controller.pageController
                    .jumpToPage(controller.currentPageIndex.value - 1),
                icon: Icon(Icons.arrow_back),
              )
            : Container()),
      ),
      body: StreamBuilder(
        stream: firestoreService.getSurahsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No data available.',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final surahsList = snapshot.data!.docs;
          surahsList.sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));

          // Map Firestore data to a usable list
          final allData = surahsList
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          List<String> surahNames =
              allData.map((data) => data['surah'] as String).toList();

          return Stack(
            children: [
              // PageView
              PageView(
                controller: controller.pageController,
                onPageChanged: controller.updatePageIndicator,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  const IntroPage(),
                  MemorisedPage(
                    surahNames: surahNames,
                    controller: controller,
                    allData: allData,
                    text: 'From what verse have you memorised?',
                    pageKey: 'from',
                  ),
                  MemorisedPage(
                    surahNames: surahNames,
                    controller: controller,
                    allData: allData,
                    text: 'To what verse have you memorised?',
                    pageKey: 'to',
                  ),
                  const PlanDetailsPage(),
                  const ReviewPage(
                    title: 'Review and Confirm',
                    description:
                        'Review your Hifdh plan and make sure everything is set before starting.',
                  ),
                ],
              ),
              // Bottom Navigation Section
              BottomNavigation(
                controller: controller,
                onNextPressed: storeNewPlan,
              ),
            ],
          );
        },
      ),
    );
  }
}

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({
    super.key,
    required this.controller,
    required this.onNextPressed,
  });

  final NewPlanController controller;
  final VoidCallback onNextPressed;
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 50.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 30),
            // Next Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ButtonStyle(
                    elevation: WidgetStateProperty.all(0),
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                    ),
                    backgroundColor: WidgetStateProperty.all(
                      const Color.fromARGB(255, 73, 121, 251),
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                  ),
                  onPressed: () {
                    if (controller.currentPageIndex.value == 4) {
                      onNextPressed();
                    }
                    controller.nextPage();
                  },
                  child: Obx(() => Text(
                        controller.currentPageIndex.value == 4
                            ? 'Confirm'
                            : 'Next',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      )),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IntroPage extends StatelessWidget {
  const IntroPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
      child: Column(
        children: [
          Icon(
            Icons.book,
            size: 50,
            color: Colors.blue.shade700,
          ),
          SizedBox(
            height: 20,
          ),
          Text(
            'Lets get some details about your memorisation',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: const Color.fromARGB(255, 31, 31, 31),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: 20,
          ),
          Text(
            "We will ask you about how much you've already memorised, what your availability is like and how much you wish to do each day.",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class MemorisedPage extends StatelessWidget {
  const MemorisedPage({
    super.key,
    required this.surahNames,
    required this.controller,
    required this.allData,
    required this.text,
    required this.pageKey,
  });

  final List<String> surahNames;
  final NewPlanController controller;
  final List<Map<String, dynamic>> allData;
  final String text;
  final String pageKey; // Key to distinguish between "from" and "to" pages

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Page Title
          Text(
            text,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: const Color.fromARGB(255, 31, 31, 31),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // QuranVersePicker wrapped with Obx for reactive updates
          Obx(
            () {
              // Determine which data to use based on pageKey
              final selectedSurahData = pageKey == 'from'
                  ? controller.selectedFromSurahData.value
                  : controller.selectedToSurahData.value;
              final selectedVerse = pageKey == 'from'
                  ? controller.selectedFromVerse.value
                  : controller.selectedToVerse.value;

              // Get the initial index for the Surah
              final initialSurahIndex = selectedSurahData != null
                  ? allData.indexOf(selectedSurahData)
                  : 0;

              return QuranVersePicker(
                surahData: allData,
                initialSurahIndex: initialSurahIndex,
                initialVerseNumber: selectedVerse,
                onVerseSelected: (surahName, verseNumber) {
                  // Update controller state based on the pageKey
                  final selectedSurah = allData
                      .firstWhere((surah) => surah['surah'] == surahName);

                  if (pageKey == 'from') {
                    controller.updateSelectedFromSurah(
                        surahName, selectedSurah);
                    controller.updateSelectedFromVerse(verseNumber);
                  } else {
                    controller.updateSelectedToSurah(surahName, selectedSurah);
                    controller.updateSelectedToVerse(verseNumber);
                  }
                },
              );
            },
          ),
          Obx(() {
            final errorMessage = pageKey == 'from'
                ? controller.fromPageError.value
                : controller.toPageError.value;
            return errorMessage.isNotEmpty
                ? Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red),
                  )
                : Container();
          }),
        ],
      ),
    );
  }
}

class PlanDetailsPage extends StatelessWidget {
  const PlanDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NewPlanController>();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            'Plan Details',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 26,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Choose how many days you want to memorize on and customize your schedule.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Amount to memorise per day',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Text Field and Dropdown Row
          Row(
            children: [
              // TextField for Input
              Expanded(
                child: TextField(
                  controller: controller.inputController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter amount',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Dropdown
              Expanded(
                child: Obx(() {
                  return MyDropDown(
                    items: ['Lines', 'Pages'],
                    value: controller.selectedUnit.value,
                    onChanged: (value) {
                      if (value != null) {
                        controller.selectedUnit.value = value;
                      }
                    },
                    text: 'Select Unit',
                  );
                }),
              ),
            ],
          ),

          const SizedBox(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Select Days',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: List.generate(7, (index) {
              return GestureDetector(
                onTap: () {
                  controller.selectedDays[index] =
                      !controller.selectedDays[index];
                },
                child: Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      color: controller.selectedDays[index]
                          ? const Color.fromARGB(255, 73, 121, 251)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      days[index],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: controller.selectedDays[index]
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          Obx(() {
            return controller.planDetailsError.value.isNotEmpty
                ? Text(
                    controller.planDetailsError.value,
                    style: TextStyle(color: Colors.red),
                  )
                : Container();
          }),
        ],
      ),
    );
  }
}

class ReviewPage extends StatelessWidget {
  const ReviewPage({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NewPlanController>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Center(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 10),

          // Description
          Center(
            child: Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 30),

          // Full-Width Section: Selected Range
          SectionCard(
            title: 'Previously Memorised',
            content:
                '${controller.selectedFromSurah.value} ${controller.selectedFromVerse.value} - ${controller.selectedToSurah.value} ${controller.selectedToVerse.value}',
            color: Colors.blue.shade50,
            borderColor: Colors.blue.shade200,
            textColor: Colors.blue.shade700,
            onEdit: () => controller.pageController.jumpToPage(1),
          ),

          const SizedBox(height: 20),

          // Full-Width Section: Selected Days
          SectionCard(
            title: 'Selected Days',
            content: controller.selectedDays
                .asMap()
                .entries
                .where((entry) => entry.value)
                .map((entry) => [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun'
                    ][entry.key])
                .join(', '),
            color: Colors.green.shade50,
            borderColor: Colors.green.shade200,
            textColor: Colors.green.shade700,
            onEdit: () => controller.pageController.jumpToPage(3),
          ),

          const SizedBox(height: 20),

          // Full-Width Section: Unit Details
          SectionCard(
            title: 'Amount per day',
            content:
                '${controller.inputController.text} ${controller.selectedUnit.value}',
            color: Colors.purple.shade50,
            borderColor: Colors.purple.shade200,
            textColor: Colors.purple.shade700,
            onEdit: () {
              controller.pageController.jumpToPage(3);
            },
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.content,
    required this.color,
    required this.borderColor,
    required this.textColor,
    required this.onEdit,
  });

  final String title;
  final String content;
  final Color color;
  final Color borderColor;
  final Color textColor;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Full width of parent
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),

              // Edit Button

              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Edit',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Content
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class NewPlanController extends GetxController {
  static NewPlanController get instance => Get.find();

  final pageController = PageController();
  Rx<int> currentPageIndex = 0.obs;
  final inputController = TextEditingController();
  final RxString selectedUnit = 'Lines'.obs;

  // Separate state for "From" and "To" pages
  final Rxn<Map<String, dynamic>> selectedFromSurahData =
      Rxn<Map<String, dynamic>>();
  final Rxn<Map<String, dynamic>> selectedToSurahData =
      Rxn<Map<String, dynamic>>();

  final Rxn<String> selectedFromSurah = Rxn<String>();
  final Rxn<String> selectedToSurah = Rxn<String>();

  final Rxn<int> selectedFromVerse = Rxn<int>();
  final Rxn<int> selectedToVerse = Rxn<int>();

  final RxList<bool> selectedDays = List.generate(7, (index) => false).obs;

  final RxString fromPageError = ''.obs;
  final RxString toPageError = ''.obs;
  final RxString planDetailsError = ''.obs;

  // Update "From" selection
  void updateSelectedFromSurah(
      String? surahName, Map<String, dynamic> surahData) {
    selectedFromSurah.value = surahName;
    selectedFromSurahData.value = surahData;
    selectedFromVerse.value = null; // Clear verse when surah changes
  }

  void updateSelectedFromVerse(int? verse) {
    selectedFromVerse.value = verse;
  }

  // Update "To" selection
  void updateSelectedToSurah(
      String? surahName, Map<String, dynamic> surahData) {
    selectedToSurah.value = surahName;
    selectedToSurahData.value = surahData;
    selectedToVerse.value = null; // Clear verse when surah changes
  }

  void updateSelectedToVerse(int? verse) {
    selectedToVerse.value = verse;
  }

  void updatePageIndicator(index) => currentPageIndex.value = index;

  void nextPage() {
    if (currentPageIndex.value == 0) {
      pageController.jumpToPage(1);
    } else if (currentPageIndex.value == 1) {
      if (selectedFromSurah.value != null && selectedFromVerse.value != null) {
        fromPageError.value = '';
        pageController.jumpToPage(2);
      } else {
        fromPageError.value = 'Please select a Surah and Verse to proceed.';
      }
    } else if (currentPageIndex.value == 2) {
      if (selectedToSurah.value != null && selectedToVerse.value != null) {
        toPageError.value = '';
        pageController.jumpToPage(3);
      } else {
        toPageError.value = 'Please select a Surah and Verse to proceed.';
      }
    } else if (currentPageIndex.value == 3) {
      if (inputController.text.isNotEmpty && selectedDays.contains(true)) {
        planDetailsError.value = '';
        pageController.jumpToPage(4);
      } else {
        planDetailsError.value =
            'Please fill out all fields and select at least one day.';
      }
    } else if (currentPageIndex.value == 4) {
      Get.to(() => MyBottomNavBar());
    }
  }
}
