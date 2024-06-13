import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hifdh_planner_app/services/firestore.dart';
import 'package:hifdh_planner_app/themes/theme_provider.dart';
import 'package:provider/provider.dart';

class NewPlanForm extends StatefulWidget {
  final List<bool> selectedDays;
  final GlobalKey<FormState> formKey;
  final bool showValidationError;
  final ValueChanged<bool> onValidationErrorChanged;
  final Function(String, String, String, String) onFormChanged;

  const NewPlanForm({
    super.key,
    required this.selectedDays,
    required this.formKey,
    required this.showValidationError,
    required this.onValidationErrorChanged,
    required this.onFormChanged,
  });

  @override
  State<NewPlanForm> createState() => _NewPlanFormState();
}

class _NewPlanFormState extends State<NewPlanForm> {
  final FirestoreService firestoreService =
      FirestoreService(FirebaseAuth.instance);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();
  final TextEditingController linesController = TextEditingController();

  String? _validateVerseKey(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a value';
    }

    if (!RegExp(r'^\d+:\d+$').hasMatch(value)) {
      return 'Invalid input format. Please enter in the format "int:int"';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Add listeners to update the stepper's state
    nameController.addListener(() {
      widget.onFormChanged(
        nameController.text,
        startController.text,
        endController.text,
        linesController.text,
      );
    });
    startController.addListener(() {
      widget.onFormChanged(
        nameController.text,
        startController.text,
        endController.text,
        linesController.text,
      );
    });
    endController.addListener(() {
      widget.onFormChanged(
        nameController.text,
        startController.text,
        endController.text,
        linesController.text,
      );
    });
    linesController.addListener(() {
      widget.onFormChanged(
        nameController.text,
        startController.text,
        endController.text,
        linesController.text,
      );
    });

    return Form(
      key: widget.formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: TextFormField(
              validator: (name) =>
                  name!.isEmpty ? 'Insert a name please...' : null,
              controller: nameController,
              decoration: const InputDecoration(
                  hintText: 'Name', border: OutlineInputBorder()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: TextFormField(
              validator: _validateVerseKey,
              controller: startController,
              decoration: const InputDecoration(
                hintText: 'Start',
                border: OutlineInputBorder(),
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: TextFormField(
              validator: _validateVerseKey,
              controller: endController,
              decoration: const InputDecoration(
                hintText: 'End',
                border: OutlineInputBorder(),
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: TextFormField(
              validator: (lines) => lines!.isEmpty
                  ? 'Insert the number of lines you wish to do...'
                  : null,
              controller: linesController,
              decoration: const InputDecoration(
                  hintText: 'Lines', border: OutlineInputBorder()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Container(
                alignment: Alignment.topLeft,
                child: const Text(
                  'Select Days',
                  style: TextStyle(fontSize: 20),
                )),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(7, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 5.0),
                    child: SizedBox(
                      height: 38,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            widget.selectedDays[index] =
                                !widget.selectedDays[index];
                            widget.onValidationErrorChanged(
                                !widget.selectedDays.contains(true));
                          });
                        },
                        style: ButtonStyle(
                          overlayColor:
                              const WidgetStatePropertyAll(Colors.transparent),
                          backgroundColor: WidgetStateProperty.all(
                            widget.selectedDays[index]
                                ? Provider.of<ThemeProvider>(context).isDarkMode
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context)
                                        .colorScheme
                                        .inversePrimary
                                : Provider.of<ThemeProvider>(context).isDarkMode
                                    ? Theme.of(context)
                                        .colorScheme
                                        .inversePrimary
                                    : Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        child: Text(
                          'MTWTFSS'[index],
                          style: TextStyle(
                            color: widget.selectedDays[index]
                                ? Provider.of<ThemeProvider>(context).isDarkMode
                                    ? Theme.of(context)
                                        .colorScheme
                                        .inversePrimary
                                    : Theme.of(context).colorScheme.secondary
                                : Provider.of<ThemeProvider>(context).isDarkMode
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context)
                                        .colorScheme
                                        .inversePrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          widget.showValidationError
              ? const Padding(
                  padding: EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    'Please select at least one day',
                    style: TextStyle(color: Color.fromRGBO(183, 88, 104, 1)),
                  ),
                )
              : const SizedBox(),
        ],
      ),
    );
  }
}
