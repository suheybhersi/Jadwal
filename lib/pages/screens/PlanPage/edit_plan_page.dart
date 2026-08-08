import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jadwal/components/daily_amount_picker.dart';
import 'package:jadwal/components/schedule_day_picker.dart';
import 'package:jadwal/services/firestore.dart';
import 'dart:math';

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

  final _formKey = GlobalKey<FormState>();
  String? _validationError;
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
    linesController.dispose();
    super.dispose();
  }

  void updatePlan(BuildContext context) {
    if (!selectedDays.contains(true)) {
      setState(() {
        _validationError = 'Please select at least one day';
      });
      return;
    }

    // Convert pages to lines if needed (minimum 1 line)
    int lines = selectedUnit == 'Lines'
        ? int.tryParse(linesController.text) ?? 0
        : (int.tryParse(linesController.text) ?? 0) * 15;
    if (lines < 1) {
      setState(() {
        _validationError = 'Daily amount must be at least 1 line';
      });
      return;
    }

    firestoreService.updatePlan(
      widget.id,
      lines,
      selectedDays,
    );

    // Clear text fields and close dialog
    linesController.clear();
    Navigator.of(context).pop();
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
      body: Form(
        key: _formKey,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
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
                  child: DailyAmountPicker(
                    compact: true,
                    unit: selectedUnit,
                    amount: max(1, int.tryParse(linesController.text) ?? 1),
                    onUnitChanged: (unit) {
                      setState(() {
                        selectedUnit = unit;
                      });
                    },
                    onAmountChanged: (amount) {
                      setState(() {
                        linesController.text = max(1, amount).toString();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
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
                  child: ScheduleDayPicker(
                    compact: true,
                    selectedDays:
                        selectedDays.map((d) => d == true).toList(),
                    onChanged: (days) {
                      setState(() {
                        selectedDays = List<dynamic>.from(days);
                        _validationError = selectedDays.contains(true)
                            ? null
                            : 'Please select at least one day';
                      });
                    },
                  ),
                ),
                if (_validationError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      _validationError!,
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      elevation: WidgetStateProperty.all(0),
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 14),
                      ),
                      backgroundColor: WidgetStateProperty.all(
                        const Color.fromARGB(255, 73, 121, 251),
                      ),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.0),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
