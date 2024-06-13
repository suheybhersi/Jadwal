import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hifdh_planner_app/components/new_daily_reading_form.dart';
import 'package:hifdh_planner_app/components/new_plan_form.dart';
import 'package:hifdh_planner_app/components/previously_memorised_form.dart';
import 'package:hifdh_planner_app/services/firestore.dart';

class MyStepper extends StatefulWidget {
  const MyStepper({super.key});

  @override
  State<MyStepper> createState() => _MyStepperState();
}

class _MyStepperState extends State<MyStepper> {
  final FirestoreService firestoreService =
      FirestoreService(FirebaseAuth.instance);

  int currentStep = 0;
  final GlobalKey<FormState> _previouslyMemorisedFormKey =
      GlobalKey<FormState>();
  final GlobalKey<FormState> _newPlanFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _dailyReadingFormKey = GlobalKey<FormState>();
  List<bool> hifdhDays = List.generate(7, (index) => false);
  List<bool> dailyReadingDays = List.generate(7, (index) => false);
  bool _showValidationError = false;

  //Previously Memorised form values
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();

  //New Plan Form values
  final TextEditingController nameController = TextEditingController();
  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();
  final TextEditingController linesController = TextEditingController();

  //New Daily Reading Form values
  final TextEditingController pagesController = TextEditingController();

  List<Step> getSteps() => [
        Step(
            isActive: currentStep >= 0,
            title: const Text('Previously Memorised'),
            content: PreviouslyMemorisedForm(
              formKey: _previouslyMemorisedFormKey,
              showValidationError: _showValidationError,
              onValidationErrorChanged: (value) {
                setState(() {
                  _showValidationError = value;
                });
              },
              onFormChanged: (from, to) {
                setState(() {
                  fromController.text = from;
                  toController.text = to;
                });
              },
            )),
        Step(
          isActive: currentStep >= 1,
          title: const Text('Plan Details'),
          content: NewPlanForm(
            selectedDays: hifdhDays,
            formKey: _newPlanFormKey,
            showValidationError: _showValidationError,
            onValidationErrorChanged: (value) {
              setState(() {
                _showValidationError = value;
              });
            },
            onFormChanged: (name, start, end, lines) {
              setState(() {
                nameController.text = name;
                startController.text = start;
                endController.text = end;
                linesController.text = lines;
              });
            },
          ),
        ),
        Step(
          isActive: currentStep >= 2,
          title: const Text('Daily Reading'),
          content: NewDailyReadingForm(
            selectedDays: dailyReadingDays,
            formKey: _dailyReadingFormKey,
            showValidationError: _showValidationError,
            onValidationErrorChanged: (value) {
              setState(() {
                _showValidationError = value;
              });
            },
            onFormChanged: (pages) {
              setState(() {
                pagesController.text = pages;
              });
            },
          ),
        )
      ];

  void _storeNewPlan(BuildContext context) {
    firestoreService.addPlan(
      nameController.text,
      startController.text,
      endController.text,
      int.parse(linesController.text),
      int.parse(pagesController.text),
      int.parse(fromController.text),
      int.parse(toController.text),
      hifdhDays,
      dailyReadingDays,
    );

    // Clear text fields and close dialog
    nameController.clear();
    startController.clear();
    endController.clear();
    linesController.clear();
    pagesController.clear();
    fromController.clear();
    toController.clear();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.only(bottom: 20),
      title: const Text('New Plan!'),
      content: SizedBox(
        width: 500,
        height: 450,
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Colors
                      .blue, // Change this to your desired active step color
                ),
          ),
          child: Stepper(
            currentStep: currentStep,
            steps: getSteps(),
            onStepContinue: () {
              final isLastStep = currentStep == getSteps().length - 1;
              if (currentStep == 0) {
                // Validate form on step 1
                if (_previouslyMemorisedFormKey.currentState!.validate()) {
                  setState(() {
                    currentStep += 1;
                  });
                }
              } else if (currentStep == 1) {
                // Validate form on step 1
                if (_newPlanFormKey.currentState!.validate() &&
                    hifdhDays.contains(true)) {
                  setState(() {
                    _showValidationError = false;
                    currentStep += 1;
                  });
                } else {
                  setState(() {
                    _showValidationError = !hifdhDays.contains(true);
                  });
                }
              } else if (isLastStep) {
                if (_dailyReadingFormKey.currentState!.validate() &&
                    dailyReadingDays.contains(true)) {
                  setState(() {
                    _showValidationError = false;
                  });
                  _storeNewPlan(context);
                } else {
                  setState(() {
                    _showValidationError = !dailyReadingDays.contains(true);
                  });
                }
              } else {
                setState(() => currentStep += 1);
              }
            },
            onStepCancel: currentStep == 0
                ? null
                : () => setState(() => currentStep -= 1),
            controlsBuilder: (BuildContext context, ControlsDetails controls) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (currentStep != 0)
                    TextButton(
                      onPressed: controls.onStepCancel,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                      ),
                      child: Text(
                        'Back',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: controls.onStepContinue,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: Text(
                      currentStep == getSteps().length - 1
                          ? 'Create'
                          : 'Continue',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
