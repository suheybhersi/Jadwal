import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hifdh_planner_app/services/firestore.dart';

class PreviouslyMemorisedForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final bool showValidationError;
  final ValueChanged<bool> onValidationErrorChanged;
  final Function(String, String) onFormChanged;

  const PreviouslyMemorisedForm({
    super.key,
    required this.formKey,
    required this.showValidationError,
    required this.onValidationErrorChanged,
    required this.onFormChanged,
  });

  @override
  State<PreviouslyMemorisedForm> createState() =>
      _PreviouslyMemorisedFormState();
}

class _PreviouslyMemorisedFormState extends State<PreviouslyMemorisedForm> {
  final FirestoreService firestoreService =
      FirestoreService(FirebaseAuth.instance);

  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();

  String? _validatePage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a value';
    } else if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Invalid input format. Please enter in the format "int"';
    } else if (int.parse(value) < 1 || int.parse(value) > 604) {
      return 'Invalid page number';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Add listeners to update the stepper's state
    fromController.addListener(() {
      widget.onFormChanged(
        fromController.text,
        toController.text,
      );
    });
    toController.addListener(() {
      widget.onFormChanged(
        fromController.text,
        toController.text,
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
              validator: _validatePage,
              controller: fromController,
              decoration: const InputDecoration(
                hintText: 'From(page number)',
                border: OutlineInputBorder(),
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: TextFormField(
              validator: _validatePage,
              controller: toController,
              decoration: const InputDecoration(
                hintText: 'To(page number)',
                border: OutlineInputBorder(),
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
          ),
        ],
      ),
    );
  }
}
