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
    linesController.text = widget.plan['lines'].toString();
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
            color: Colors.black87,
          ),
        ),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.blue.shade50,
                    width: 1,
                  ),
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
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'How much would you like to memorise?',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
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
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
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
                                      color: Colors.black87,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.blue.shade50,
                    width: 1,
                  ),
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
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Select your memorisation days',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
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
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedDays[index]
                                      ? Colors.transparent
                                      : Colors.grey.shade300,
                                ),
                                boxShadow: selectedDays[index]
                                    ? [
                                        BoxShadow(
                                          color: const Color.fromARGB(
                                                  255, 73, 121, 251)
                                              .withOpacity(0.3),
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
                                      : Colors.grey.shade700,
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
