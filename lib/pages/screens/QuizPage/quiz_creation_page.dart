import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/components/verse_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_creation_controller.dart';
import 'package:jadwal/services/firestore.dart';

class QuizCreationPage extends StatelessWidget {
  const QuizCreationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize FirestoreService
    final firestoreService = FirestoreService(
      auth: FirebaseAuth.instance,
      uid: FirebaseAuth.instance.currentUser!.uid,
    );

    // Initialize and register the controller
    final controller =
        Get.put(QuizCreationController(firestoreService: firestoreService));

    final textColor = Theme.of(context).colorScheme.inversePrimary;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Create Quiz',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => controller.goBack(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getSurahsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading(Theme.of(context).colorScheme.primary);
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildNoData();
          }

          // Process surah data
          final surahsList = snapshot.data!.docs;
          surahsList.sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));
          final allData = surahsList
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          return Stack(
            children: [
              Column(
                children: [
                  // Step indicators
                  _buildStepIndicator(controller, context),

                  // Main content
                  Expanded(
                    child: PageView(
                      controller: controller.pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (int page) {
                        controller.currentPage.value = page;
                      },
                      children: [
                        // Step 1: Question Types
                        _buildQuestionTypesPage(
                            controller, Theme.of(context).colorScheme.primary),

                        // Step 2: Start Verse Selection
                        _buildStartVerseSelectionPage(controller, allData,
                            Theme.of(context).colorScheme.primary, textColor),

                        // Step 3: End Verse Selection
                        _buildEndVerseSelectionPage(controller, allData,
                            Theme.of(context).colorScheme.primary, textColor),
                      ],
                    ),
                  ),

                  // Navigation buttons
                  _buildNavigationButtons(controller, allData,
                      Theme.of(context).colorScheme.primary, context),
                ],
              ),

              // Loading overlay
              Obx(() => controller.isLoading.value
                  ? _buildLoadingOverlay(
                      Theme.of(context).colorScheme.primary, textColor)
                  : const SizedBox.shrink()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator(
      QuizCreationController controller, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepCircle(controller, 0, 'Types', context),
              _buildStepLine(controller, 0),
              _buildStepCircle(controller, 1, 'Start', context),
              _buildStepLine(controller, 1),
              _buildStepCircle(controller, 2, 'End', context),
            ],
          )),
    );
  }

  Widget _buildStepCircle(QuizCreationController controller, int step,
      String label, BuildContext context) {
    final isActive = controller.currentPage.value >= step;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? primaryColor : Colors.grey.shade300,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: GoogleFonts.poppins(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: isActive ? primaryColor : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(QuizCreationController controller, int step) {
    final isActive = controller.currentPage.value > step;
    final primaryColor = const Color.fromARGB(255, 73, 121, 251);

    return Container(
      width: 70,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isActive ? primaryColor : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildQuestionTypesPage(
      QuizCreationController controller, Color primaryColor) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withValues(alpha: 0.8),
                    primaryColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Iconsax.clipboard_text,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Select Question Types',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose the types of questions you want to include in your quiz.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Fill in the Blank
            Obx(() => _buildQuestionTypeCard(
                  icon: Iconsax.document_text,
                  title: 'Fill in the Blank',
                  isSelected: controller.includeFillBlank.value,
                  onToggle: (value) {
                    controller.includeFillBlank.value = value;
                  },
                )),

            // Drag and Drop
            Obx(() => _buildQuestionTypeCard(
                  icon: Iconsax.hierarchy_square_3,
                  title: 'Drag and Drop',
                  isSelected: controller.includeDragDrop.value,
                  onToggle: (value) {
                    controller.includeDragDrop.value = value;
                  },
                )),

            // What Comes Next
            Obx(() => _buildQuestionTypeCard(
                  icon: Iconsax.arrow_right,
                  title: 'What Comes Next',
                  isSelected: controller.includeWhatNext.value,
                  onToggle: (value) {
                    controller.includeWhatNext.value = value;
                  },
                )),

            // Verse Pairing
            Obx(() => _buildQuestionTypeCard(
                  icon: Iconsax.link,
                  title: 'Verse Pairing',
                  isSelected: controller.includeVersePairing.value,
                  onToggle: (value) {
                    controller.includeVersePairing.value = value;
                  },
                )),

            // Warning when no type is selected
            Obx(() => !controller.isAnyTypeSelected()
                ? Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.red.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red.shade800,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Please select at least one question type',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.red.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  Widget _buildStartVerseSelectionPage(QuizCreationController controller,
      List<Map<String, dynamic>> allData, Color primaryColor, Color textColor) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withValues(alpha: 0.8),
                    primaryColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Iconsax.book_1,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Select Starting Verse',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose the starting verse for your quiz.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Start verse selection
            _buildVersePicker(
              allData,
              controller.selectedStartSurahData.value,
              controller.selectedStartVerse.value,
              (surahName, verseNumber) => controller.handleStartVerseSelection(
                  allData, surahName, verseNumber),
            ),

            // Error Message
            Obx(() => controller.selectionErrorMessage.value.isNotEmpty
                ? _buildErrorMessage(controller)
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  Widget _buildEndVerseSelectionPage(QuizCreationController controller,
      List<Map<String, dynamic>> allData, Color primaryColor, Color textColor) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withValues(alpha: 0.8),
                    primaryColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Iconsax.book_1,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Select Ending Verse',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose the ending verse for your quiz.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // End verse selection
            _buildVersePicker(
              allData,
              controller.selectedEndSurahData.value ??
                  controller.selectedStartSurahData.value,
              controller.selectedEndVerse.value,
              (surahName, verseNumber) => controller.handleEndVerseSelection(
                  allData, surahName, verseNumber),
            ),

            // Error Message
            Obx(() => controller.selectionErrorMessage.value.isNotEmpty
                ? _buildErrorMessage(controller)
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(
      QuizCreationController controller,
      List<Map<String, dynamic>> allData,
      Color primaryColor,
      BuildContext context) {
    return Obx(() {
      if (controller.currentPage.value == 0) {
        // Question type selection page - Next button
        return Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 30.0),
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: controller.isAnyTypeSelected()
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: ElevatedButton(
              onPressed: controller.isAnyTypeSelected()
                  ? () => controller.goToNextPage()
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Next',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
        );
      } else if (controller.currentPage.value == 1) {
        // Start verse selection page - Next button
        return Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 30.0),
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: controller.selectedStartVerse.value != null
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: ElevatedButton(
              onPressed: controller.selectedStartVerse.value != null
                  ? () => controller.goToNextPage()
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Next',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
        );
      } else {
        // End verse selection page - Create Quiz button
        return Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 30.0),
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: controller.canCreateQuiz()
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: ElevatedButton(
              onPressed: controller.canCreateQuiz()
                  ? () => controller.createQuiz(allData, context)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.play, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    'Create Quiz',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    });
  }

  Widget _buildQuestionTypeCard({
    required IconData icon,
    required String title,
    required bool isSelected,
    required Function(bool) onToggle,
  }) {
    return Builder(
      builder: (context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isSelected
                ? const Color.fromARGB(255, 73, 121, 251).withValues(alpha: 0.5)
                : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: () => onToggle(!isSelected),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color.fromARGB(255, 73, 121, 251)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color.fromARGB(255, 73, 121, 251)
                        : Colors.grey.withValues(alpha: 0.1),
                    border: Border.all(
                      color: isSelected
                          ? const Color.fromARGB(255, 73, 121, 251)
                          : Colors.grey.shade400,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 18,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersePicker(
    List<Map<String, dynamic>> allData,
    Map<String, dynamic>? selectedSurahData,
    int? selectedVerse,
    Function(String, int) onVerseSelected,
  ) {
    return QuranVersePicker(
      key:
          ValueKey('${selectedSurahData?.hashCode ?? 0}-${selectedVerse ?? 0}'),
      surahData: allData,
      initialSurahIndex:
          selectedSurahData != null ? allData.indexOf(selectedSurahData) : 0,
      initialVerseNumber: selectedVerse,
      onVerseSelected: onVerseSelected,
    );
  }

  Widget _buildErrorMessage(QuizCreationController controller) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.shade200,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              color: Colors.red.shade800,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              controller.selectionErrorMessage.value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade800,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay(Color primaryColor, Color textColor) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 30),
          decoration: BoxDecoration(
            color: Get.theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  color: primaryColor,
                  strokeWidth: 5,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Preparing your quiz...',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This might take a moment',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(Color primaryColor) {
    return Center(
      child: CircularProgressIndicator(
        color: primaryColor,
      ),
    );
  }

  Widget _buildNoData() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.information,
            size: 60,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No surahs data available',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
