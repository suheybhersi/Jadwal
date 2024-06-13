import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hifdh_planner_app/services/firestore.dart';
import 'package:hifdh_planner_app/themes/theme_provider.dart';
import 'package:provider/provider.dart';

class NewDailyReadingForm extends StatefulWidget {
  final List<bool> selectedDays;
  final GlobalKey<FormState> formKey;
  final bool showValidationError;
  final ValueChanged<bool> onValidationErrorChanged;
  final Function(String) onFormChanged;

  const NewDailyReadingForm({
    super.key,
    required this.selectedDays,
    required this.formKey,
    required this.showValidationError,
    required this.onValidationErrorChanged,
    required this.onFormChanged,
  });

  @override
  State<NewDailyReadingForm> createState() => _NewDailyReadingFormState();
}

class _NewDailyReadingFormState extends State<NewDailyReadingForm> {
  final FirestoreService firestoreService =
      FirestoreService(FirebaseAuth.instance);

  final TextEditingController pagesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Add listeners to update the stepper's state

    pagesController.addListener(() {
      widget.onFormChanged(
        pagesController.text,
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
              validator: (lines) => lines!.isEmpty
                  ? 'Insert the number of pages you wish to do...'
                  : null,
              controller: pagesController,
              decoration: const InputDecoration(
                  hintText: 'Pages', border: OutlineInputBorder()),
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
