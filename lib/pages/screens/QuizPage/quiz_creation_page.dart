import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/components/verse_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:jadwal/pages/auth/widgets/auth_widgets.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_creation_controller.dart';
import 'package:jadwal/services/firestore.dart';
import 'package:jadwal/services/subscription_service.dart';
import 'package:provider/provider.dart';

class QuizCreationPage extends StatefulWidget {
  const QuizCreationPage({super.key});

  @override
  State<QuizCreationPage> createState() => _QuizCreationPageState();
}

class _QuizCreationPageState extends State<QuizCreationPage> {
  late final QuizCreationController controller;

  @override
  void initState() {
    super.initState();
    final firestoreService = FirestoreService(
      auth: FirebaseAuth.instance,
      uid: FirebaseAuth.instance.currentUser!.uid,
    );

    if (Get.isRegistered<QuizCreationController>()) {
      Get.delete<QuizCreationController>(force: true);
    }
    controller =
        Get.put(QuizCreationController(firestoreService: firestoreService));
  }

  @override
  void dispose() {
    if (Get.isRegistered<QuizCreationController>()) {
      Get.delete<QuizCreationController>(force: true);
    }
    super.dispose();
  }

  String _rangeLabel() {
    final startName = controller.selectedStartSurahName.value;
    final startVerse = controller.selectedStartVerse.value;
    final endName = controller.selectedEndSurahName.value;
    final endVerse = controller.selectedEndVerse.value;

    if (startName == null ||
        startVerse == null ||
        endName == null ||
        endVerse == null) {
      return 'Choose verses';
    }

    if (startName == endName) {
      return '$startName · $startVerse–$endVerse';
    }
    return '$startName $startVerse – $endName $endVerse';
  }

  Future<void> _openRangeSheet(
    BuildContext context,
    List<Map<String, dynamic>> allData,
  ) async {
    controller.setDefaultStartVerseIfNeeded(allData);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return _QuizRangePickerSheet(
          controller: controller,
          allData: allData,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
            fontSize: 20,
            color: textColor,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => controller.goBack(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: controller.firestoreService.getSurahsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kAuthBrandBlue),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No surahs data available',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            );
          }

          final surahsList = snapshot.data!.docs;
          surahsList.sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));
          final allData = surahsList.map((doc) {
            final data = Map<String, dynamic>.from(
              doc.data() as Map<String, dynamic>,
            );
            data['surahNumber'] =
                QuizCreationController.parseSurahNumber(data['surahNumber']) ??
                    int.tryParse(doc.id) ??
                    data['surahNumber'];
            return data;
          }).toList();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            controller.setDefaultStartVerseIfNeeded(allData);
          });

          return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose verses and how you want to be tested.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Obx(
                            () => Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _openRangeSheet(context, allData),
                                borderRadius: BorderRadius.circular(14),
                                child: Ink(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kAuthBrandBlue.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color:
                                          kAuthBrandBlue.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Iconsax.book_1,
                                        color: kAuthBrandBlue,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _rangeLabel(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Change',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: kAuthBrandBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Question types',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Obx(
                            () => _buildQuestionTypeCard(
                              icon: Iconsax.hierarchy_square_3,
                              title: 'Drag and Drop',
                              isSelected: controller.includeDragDrop.value,
                              onToggle: (value) {
                                controller.includeDragDrop.value = value;
                              },
                            ),
                          ),
                          Obx(
                            () => _buildQuestionTypeCard(
                              icon: Iconsax.link,
                              title: 'Verse Pairing',
                              isSelected: controller.includeVersePairing.value,
                              onToggle: (value) {
                                controller.includeVersePairing.value = value;
                              },
                            ),
                          ),
                          Obx(() {
                            final isPro =
                                context.watch<SubscriptionService>().isPro;
                            return _buildQuestionTypeCard(
                              icon: Iconsax.document_text,
                              title: 'Fill in the Blank',
                              isSelected: controller.includeFillBlank.value,
                              showProBadge: true,
                              onToggle: (value) {
                                if (!isPro) {
                                  context
                                      .read<SubscriptionService>()
                                      .openPaywall(context);
                                  return;
                                }
                                controller.includeFillBlank.value = value;
                              },
                            );
                          }),
                          Obx(() {
                            final isPro =
                                context.watch<SubscriptionService>().isPro;
                            return _buildQuestionTypeCard(
                              icon: Iconsax.arrow_right,
                              title: 'What Comes Next',
                              isSelected: controller.includeWhatNext.value,
                              showProBadge: true,
                              showBetaBadge: true,
                              subtitle:
                                  'In testing — it may not work as expected',
                              onToggle: (value) {
                                if (!isPro) {
                                  context
                                      .read<SubscriptionService>()
                                      .openPaywall(context);
                                  return;
                                }
                                controller.includeWhatNext.value = value;
                              },
                            );
                          }),
                          Obx(() {
                            final msg = controller.selectionErrorMessage.value;
                            if (msg.isEmpty) return const SizedBox.shrink();
                            return _buildErrorMessage(msg);
                          }),
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Obx(() {
                        final canCreate = controller.canCreateQuiz();
                        return AuthPrimaryButton(
                          label: 'Create Quiz',
                          enabled: canCreate,
                          onPressed: canCreate
                              ? () => controller.createQuiz(allData, context)
                              : null,
                        );
                      }),
                    ),
                  ),
                ],
          );
        },
      ),
    );
  }

  Widget _buildQuestionTypeCard({
    required IconData icon,
    required String title,
    required bool isSelected,
    required ValueChanged<bool> onToggle,
    String? subtitle,
    bool showBetaBadge = false,
    bool showProBadge = false,
  }) {
    final textColor = Theme.of(context).colorScheme.inversePrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onToggle(!isSelected),
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? kAuthBrandBlue.withValues(alpha: 0.45)
                    : Colors.grey.shade200,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? kAuthBrandBlue
                        : Colors.grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ),
                          if (showBetaBadge) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: Colors.amber.shade700,
                                ),
                              ),
                              child: Text(
                                'Beta',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                          if (showProBadge) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: kAuthBrandBlue.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                'Pro',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: kAuthBrandBlue,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  isSelected ? Iconsax.tick_circle5 : Iconsax.tick_circle,
                  size: 20,
                  color: isSelected ? kAuthBrandBlue : Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade800, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two-step range sheet: pick start first, then end (excluding earlier verses).
class _QuizRangePickerSheet extends StatefulWidget {
  const _QuizRangePickerSheet({
    required this.controller,
    required this.allData,
  });

  final QuizCreationController controller;
  final List<Map<String, dynamic>> allData;

  @override
  State<_QuizRangePickerSheet> createState() => _QuizRangePickerSheetState();
}

class _QuizRangePickerSheetState extends State<_QuizRangePickerSheet> {
  /// 0 = start, 1 = end
  int _step = 0;

  QuizCreationController get controller => widget.controller;
  List<Map<String, dynamic>> get allData => widget.allData;

  Widget _rangeEndpointChip(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final textColor = Theme.of(context).colorScheme.inversePrimary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kAuthBrandBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: kAuthBrandBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Iconsax.book_1,
            color: kAuthBrandBlue,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goToEndStep() {
    controller.prepareEndDefaultAfterStart(allData);
    final options = controller.endSurahOptions(allData);
    if (options.isEmpty) {
      controller.selectionErrorMessage.value =
          'No verses after this start. Choose an earlier start verse.';
      setState(() {});
      return;
    }
    setState(() => _step = 1);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.inversePrimary;
    final isStart = _step == 0;
    final endOptions =
        isStart ? const <Map<String, dynamic>>[] : controller.endSurahOptions(allData);
    final minEndVerse = controller.endMinVerseForFilteredList(endOptions);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Row(
                  children: [
                    if (!isStart)
                      IconButton(
                        onPressed: () => setState(() => _step = 0),
                        icon: const Icon(Icons.arrow_back),
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: Text(
                        isStart ? 'Choose start verse' : 'Choose end verse',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              if (!isStart) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _rangeEndpointChip(
                    context,
                    label: 'Start',
                    value:
                        '${controller.selectedStartSurahName.value} · ${controller.selectedStartVerse.value}',
                  ),
                ),
              ],
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  children: [
                    if (isStart) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                        child: Text(
                          'Start',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                      QuranVersePicker(
                        key: const ValueKey('quiz-start-picker'),
                        surahData: allData,
                        initialSurahIndex: QuizCreationController.indexOfSurah(
                          allData,
                          controller.selectedStartSurahData.value,
                        ),
                        initialVerseNumber: controller.selectedStartVerse.value,
                        onVerseSelected: (surahName, verseNumber) {
                          controller.handleStartVerseSelection(
                            allData,
                            surahName,
                            verseNumber,
                          );
                        },
                      ),
                      if (controller.selectedEndSurahName.value != null &&
                          controller.selectedEndVerse.value != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
                          child: _rangeEndpointChip(
                            context,
                            label: 'End',
                            value:
                                '${controller.selectedEndSurahName.value} · ${controller.selectedEndVerse.value}',
                          ),
                        ),
                    ] else if (endOptions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No verses after this start. Go back and choose an earlier start.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                        child: Text(
                          'End',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                      QuranVersePicker(
                        key: ValueKey(
                          'quiz-end-picker-${controller.selectedStartSurahName.value}-${controller.selectedStartVerse.value}',
                        ),
                        surahData: endOptions,
                        initialSurahIndex: QuizCreationController.indexOfSurah(
                          endOptions,
                          controller.selectedEndSurahData.value,
                        ),
                        initialVerseNumber: controller.selectedEndVerse.value,
                        minVerseNumber: minEndVerse,
                        onVerseSelected: (surahName, verseNumber) {
                          controller.handleEndVerseSelection(
                            allData,
                            surahName,
                            verseNumber,
                          );
                        },
                      ),
                    ],
                    Obx(() {
                      final msg = controller.selectionErrorMessage.value;
                      if (msg.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                        child: Text(
                          msg,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.red.shade700,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: AuthPrimaryButton(
                  label: isStart ? 'Continue' : 'Done',
                  onPressed: () {
                    if (isStart) {
                      _goToEndStep();
                    } else {
                      controller.validateSelection();
                      if (controller.selectionErrorMessage.value.isEmpty) {
                        Navigator.pop(context);
                      } else {
                        setState(() {});
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
