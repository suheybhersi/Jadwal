import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jadwal/services/firestore.dart';
import 'dart:async';
import 'package:jadwal/components/drop_down.dart';

// ignore: must_be_immutable
class EditPlanPage extends StatefulWidget {
  Map<String, dynamic> plan;
  String id;
  EditPlanPage({super.key, required this.plan, required this.id});

  @override
  State<EditPlanPage> createState() => _EditPlanPageState();
}

class _EditPlanPageState extends State<EditPlanPage> {
  final FirestoreService firestoreService = FirestoreService(
    auth: FirebaseAuth.instance,
    uid: FirebaseAuth.instance.currentUser!.uid,
  );
  final TextEditingController linesController = TextEditingController();
  String selectedUnit = 'Lines';
  Timer? activeTimer;

  final _formKey = GlobalKey<FormState>();
  bool _showValidationError = false;
  List<dynamic> selectedDays = [];

  @override
  void initState() {
    super.initState();
    // Initialise with the current plan days
    selectedDays = List.from(widget.plan['hifdhDays']);
    selectedUnit = widget.plan['lines'] % 15 == 0 ? 'Pages' : 'Lines';
    linesController.text = (widget.plan['lines'] % 15 == 0
            ? widget.plan['lines'] ~/ 15
            : widget.plan['lines'])
        .toString();
  }

  @override
  void dispose() {
    activeTimer?.cancel();
    linesController.dispose();
    super.dispose();
  }

  void updatePlan(BuildContext context) {
    if (!selectedDays.contains(true)) {
      setState(() {
        _showValidationError = true;
      });
      return;
    }

    // Convert pages to lines if needed
    int lines = selectedUnit == 'Lines'
        ? int.parse(linesController.text)
        : int.parse(linesController.text) * 15;

    firestoreService.updatePlan(
      widget.id,
      lines,
      selectedDays,
    );

    // Clear text fields and close dialog
    linesController.clear();
    Navigator.of(context).pop();
  }

  void _incrementLines() {
    final currentValue = int.tryParse(linesController.text) ?? 0;
    setState(() {
      linesController.text = (currentValue + 1).toString();
    });
  }

  void _decrementLines() {
    final currentValue = int.tryParse(linesController.text) ?? 0;
    if (currentValue > 0) {
      setState(() {
        linesController.text = (currentValue - 1).toString();
      });
    }
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: Offset(0.0, 10.0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: Colors.red[700],
                  size: 32,
                ),
              ),

              SizedBox(height: 24),

              // Title
              Text(
                'Reset Plan',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),

              SizedBox(height: 16),

              // Content
              Text(
                'This will erase ALL your memorisation progress, including hifdh records, reviews, and statistics.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .inversePrimary
                      .withValues(alpha: 0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 8),

              // Warning
              Text(
                'This action cannot be undone.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 32),

              // Buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Theme.of(context)
                              .colorScheme
                              .inversePrimary
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 16),

                  // Reset button
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => Center(
                            child: CircularProgressIndicator(
                              color: Colors.blue[700],
                            ),
                          ),
                        );

                        // Reset the plan
                        firestoreService.resetPlan().then((_) {
                          // Close loading dialog
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          // Close confirmation dialog
                          Navigator.pop(context);
                          // Navigate back to main screen
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Plan reset successfully',
                                style: GoogleFonts.poppins(),
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }).catchError((error) {
                          // Handle errors
                          if (!context.mounted) return;
                          Navigator.pop(context); // Close loading dialog
                          Navigator.pop(context); // Close confirmation dialog

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error resetting plan: $error',
                                style: GoogleFonts.poppins(),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        });
                      },
                      child: Text(
                        'Reset',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          'Edit Plan',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline,
                color: Theme.of(context).colorScheme.inversePrimary),
            onPressed: () => _showResetConfirmation(context),
            tooltip: 'Reset Plan',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Daily Amount Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .tertiary
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Amount',
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(context).colorScheme.inversePrimary),
                        ),
                        Text(
                          'How much would you like to memorise?',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .inversePrimary
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .tertiary
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTapDown: (TapDownDetails details) {
                                    Timer? timer;
                                    timer = Timer.periodic(
                                        const Duration(milliseconds: 100),
                                        (timer) {
                                      final currentValue =
                                          int.tryParse(linesController.text) ??
                                              0;
                                      if (currentValue > 0) {
                                        setState(() {
                                          linesController.text =
                                              (currentValue - 1).toString();
                                        });
                                      }
                                    });
                                    activeTimer = timer;
                                  },
                                  onTapUp: (_) {
                                    activeTimer?.cancel();
                                  },
                                  onTapCancel: () {
                                    activeTimer?.cancel();
                                  },
                                  child: IconButton(
                                    onPressed: _decrementLines,
                                    icon: Icon(
                                      Icons.remove,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    linesController.text,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inversePrimary,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTapDown: (TapDownDetails details) {
                                    Timer? timer;
                                    timer = Timer.periodic(
                                        const Duration(milliseconds: 100),
                                        (timer) {
                                      final currentValue =
                                          int.tryParse(linesController.text) ??
                                              0;
                                      setState(() {
                                        linesController.text =
                                            (currentValue + 1).toString();
                                      });
                                    });
                                    activeTimer = timer;
                                  },
                                  onTapUp: (_) {
                                    activeTimer?.cancel();
                                  },
                                  onTapCancel: () {
                                    activeTimer?.cancel();
                                  },
                                  child: IconButton(
                                    onPressed: _incrementLines,
                                    icon: Icon(
                                      Icons.add,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: MyDropDown(
                            items: ['Lines', 'Pages'],
                            value: selectedUnit,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedUnit = value;
                                });
                              }
                            },
                            text: 'Unit',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Days Selection Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .tertiary
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                        Text(
                          'Select your memorisation days',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .inversePrimary
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(7, (index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedDays[index] = !selectedDays[index];
                                _showValidationError =
                                    !selectedDays.contains(true);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: selectedDays[index]
                                    ? const Color.fromARGB(255, 73, 121, 251)
                                    : Theme.of(context).colorScheme.tertiary,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedDays[index]
                                      ? Colors.transparent
                                      : Theme.of(context).colorScheme.tertiary,
                                ),
                                boxShadow: selectedDays[index]
                                    ? [
                                        BoxShadow(
                                          color: const Color.fromARGB(
                                                  255, 73, 121, 251)
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          spreadRadius: 0,
                                        )
                                      ]
                                    : [],
                              ),
                              child: Text(
                                days[index],
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: selectedDays[index]
                                      ? Colors.white
                                      : Theme.of(context)
                                          .colorScheme
                                          .inversePrimary
                                          .withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              // Error message
              if (_showValidationError)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Please select at least one day',
                    style: GoogleFonts.poppins(
                      color: Colors.red,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const Spacer(),

              // Submit Button
              Padding(
                padding: const EdgeInsets.only(bottom: 40, left: 16, right: 16),
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
                    onPressed: () => updatePlan(context),
                    child: Text(
                      'Update',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
