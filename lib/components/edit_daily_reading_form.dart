import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hifdh_planner_app/services/firestore.dart';
import 'package:hifdh_planner_app/themes/theme_provider.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class EditDailyReadingForm extends StatefulWidget {
  Map<String, dynamic> plan;
  String id;
  EditDailyReadingForm({super.key, required this.plan, required this.id});

  @override
  State<EditDailyReadingForm> createState() => _EditDailyReadingFormState();
}

class _EditDailyReadingFormState extends State<EditDailyReadingForm> {
  final FirestoreService firestoreService =
      FirestoreService(FirebaseAuth.instance);
  final TextEditingController pagesController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _showValidationError = false;

  void updateDailyReading(BuildContext context, List<dynamic> selectedDays) {
    firestoreService.updateDailyReading(
      widget.id,
      pagesController.text.isEmpty
          ? widget.plan['pages']
          : int.parse(pagesController.text),
      selectedDays,
    );

    // Clear text fields and close dialog
    pagesController.clear();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> selectedDays = widget.plan['dailyReadingDays'];

    return AlertDialog(
      scrollable: true,
      title: const Text(
        'Edit plan',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: TextFormField(
                controller: pagesController,
                decoration: InputDecoration(
                  hintText: widget.plan['pages'].toString(),
                  border: const OutlineInputBorder(),
                ),
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
                              selectedDays[index] = !selectedDays[index];
                              _showValidationError =
                                  !selectedDays.contains(true);
                            });
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              selectedDays[index]
                                  ? Provider.of<ThemeProvider>(context)
                                          .isDarkMode
                                      ? Theme.of(context).colorScheme.secondary
                                      : Theme.of(context)
                                          .colorScheme
                                          .inversePrimary
                                  : Provider.of<ThemeProvider>(context)
                                          .isDarkMode
                                      ? Theme.of(context)
                                          .colorScheme
                                          .inversePrimary
                                      : Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          child: Text(
                            'MTWTFSS'[index],
                            style: TextStyle(
                              color: selectedDays[index]
                                  ? Provider.of<ThemeProvider>(context)
                                          .isDarkMode
                                      ? Theme.of(context)
                                          .colorScheme
                                          .inversePrimary
                                      : Theme.of(context).colorScheme.secondary
                                  : Provider.of<ThemeProvider>(context)
                                          .isDarkMode
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
            _showValidationError
                ? const Padding(
                    padding: EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      'Please select at least one day',
                      style: TextStyle(color: Color.fromRGBO(183, 88, 104, 1)),
                    ),
                  )
                : const SizedBox(),
            TextButton(
              onPressed: () {
                !_formKey.currentState!.validate();
                if (selectedDays.contains(true) &&
                    _formKey.currentState!.validate()) {
                  updateDailyReading(context, selectedDays);
                }
                setState(() {
                  _showValidationError = !selectedDays.contains(true);
                });
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(
                  Provider.of<ThemeProvider>(context).isDarkMode
                      ? Theme.of(context).colorScheme.inversePrimary
                      : Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              child: Text(
                'Submit',
                style: TextStyle(
                    color: Provider.of<ThemeProvider>(context).isDarkMode
                        ? Theme.of(context).colorScheme.surface
                        : Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
