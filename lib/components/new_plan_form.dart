import 'package:flutter/material.dart';
import 'package:hifdh_planner_app/services/firestore.dart';
import 'package:hifdh_planner_app/themes/theme_provider.dart';
import 'package:provider/provider.dart';

class NewPlanForm extends StatefulWidget {
  final List<bool> selectedDays;
  const NewPlanForm({super.key, required this.selectedDays});

  @override
  State<NewPlanForm> createState() => _NewPlanFormState();
}

class _NewPlanFormState extends State<NewPlanForm> {
  final FirestoreService firestoreService = FirestoreService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();
  final TextEditingController linesController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String? _validateVerseKey(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a value';
    }

    if (!RegExp(r'^\d+:\d+$').hasMatch(value)) {
      return 'Invalid input format. Please enter in the format "int:int"';
    }

    return null;
  }

  void _storeNewPlan(BuildContext context) {
/*
- - - - - - - - - - - - - - - - A D D   N E W   P L A N   T O   D A T A B A S E - - - - - - - - - - - - - - - - 
*/

    firestoreService.addPlan(
      nameController.text,
      startController.text,
      endController.text,
      linesController.text.isEmpty ? 0 : int.parse(linesController.text),
      widget.selectedDays,
    );

    // Clear text fields and close dialog
    nameController.clear();
    startController.clear();
    endController.clear();
    linesController.clear();
    Navigator.of(context).pop();
  }

  bool _showValidationError = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text(
        'Add new plan',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
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
                              _showValidationError =
                                  !widget.selectedDays.contains(true);
                            });
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              widget.selectedDays[index]
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
                              color: widget.selectedDays[index]
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
                if (widget.selectedDays.contains(true) &&
                    _formKey.currentState!.validate()) {
                  _storeNewPlan(context);
                }
                setState(() {
                  _showValidationError = !widget.selectedDays.contains(true);
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
