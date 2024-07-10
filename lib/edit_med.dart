import 'package:flutter/material.dart';
import 'database_helper.dart';

class EditMedicationPage extends StatefulWidget {
  final Map<String, dynamic> medication;

  EditMedicationPage({required this.medication});

  @override
  _EditMedicationPageState createState() => _EditMedicationPageState();
}

class _EditMedicationPageState extends State<EditMedicationPage> {
  late TextEditingController _activeIngredientController;
  late TextEditingController _brandNameController;
  late TextEditingController _dosageController;
  late TextEditingController _dosagePerDayController;
  late TextEditingController _timeIntervalController;

  @override
  void initState() {
    super.initState();
    _activeIngredientController =
        TextEditingController(text: widget.medication['activeIngredient']);
    _brandNameController =
        TextEditingController(text: widget.medication['brandName']);
    _dosageController =
        TextEditingController(text: widget.medication['dosage'].toString());
    _dosagePerDayController = TextEditingController(
        text: widget.medication['dosagePerDay']?.toString() ?? '');
    _timeIntervalController =
        TextEditingController(text: widget.medication['doseTimeInterval']);
  }

  void _saveEdits() async {
    Map<String, dynamic> updatedMedication = {
      'id': widget.medication['id'],
      'profileId': widget.medication['profileId'],
      'activeIngredient': _activeIngredientController.text,
      'brandName': _brandNameController.text,
      'dosage': double.tryParse(
          _dosageController.text), // Ensure dosage is stored correctly
      'dosagePerDay': int.tryParse(_dosagePerDayController.text),
      'doseTimeInterval': _timeIntervalController.text,
      'medicationType': widget.medication['medicationType'],
      'predeterminedTimes': widget.medication['predeterminedTimes'],
    };

    try {
      await DatabaseHelper().updateMedication(updatedMedication);
      Navigator.pop(context,
          true); // Return true to indicate that the medication was updated
    } catch (e) {
      print('Error updating medication: $e');
      _showErrorDialog('Failed to update medication: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _activeIngredientController.dispose();
    _brandNameController.dispose();
    _dosageController.dispose();
    _dosagePerDayController.dispose();
    _timeIntervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Medication'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _activeIngredientController,
              decoration: InputDecoration(labelText: 'Active Ingredient'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _brandNameController,
              decoration: InputDecoration(labelText: 'Brand Name'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _dosageController,
              decoration: InputDecoration(labelText: 'Dosage'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _dosagePerDayController,
              decoration: InputDecoration(labelText: 'Dosage Per Day'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _timeIntervalController,
              decoration:
                  InputDecoration(labelText: 'Time Interval Between Dosages'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveEdits,
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
