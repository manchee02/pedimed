import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

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
  List<TimeOfDay> _predeterminedTimes = [];

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
    if (widget.medication['predeterminedTimes'] != null &&
        widget.medication['predeterminedTimes'].isNotEmpty) {
      List<String> times = List<String>.from(
          jsonDecode(widget.medication['predeterminedTimes']));
      _predeterminedTimes =
          times.map((timeStr) => _parseTime(timeStr)).toList();
    }
    _updateDosagePerDay(); // Update dosage per day based on initial times
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final format = DateFormat.jm(); // 12-hour format with AM/PM
      DateTime dateTime = format.parse(timeStr);
      return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    } catch (e) {
      print('Error parsing time: $e');
      throw FormatException('Invalid time format');
    }
  }

  void _updateDosagePerDay() {
    setState(() {
      _dosagePerDayController.text = _predeterminedTimes.length.toString();
    });
  }

  void _saveEdits() async {
    List<String> times =
        _predeterminedTimes.map((time) => _formatTimeOfDay(time)).toList();
    Map<String, dynamic> updatedMedication = {
      'id': widget.medication['id'],
      'profileId': widget.medication['profileId'],
      'profileName': widget.medication['profileName'],
      'activeIngredient': _activeIngredientController.text,
      'brandName': _brandNameController.text,
      'dosage': double.tryParse(
          _dosageController.text), // Ensure dosage is stored correctly
      'dosagePerDay': int.tryParse(_dosagePerDayController.text),
      'doseTimeInterval': _timeIntervalController.text,
      'predeterminedTimes': jsonEncode(times),
      'medicationType': widget.medication['medicationType'],
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

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final formattedTime = DateFormat.jm().format(DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    ));
    return formattedTime;
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

  Future<void> _addTime() async {
    TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (newTime != null) {
      setState(() {
        _predeterminedTimes.add(newTime);
        _updateDosagePerDay(); // Update dosage per day
      });
    }
  }

  void _removeTime(int index) {
    setState(() {
      _predeterminedTimes.removeAt(index);
      _updateDosagePerDay(); // Update dosage per day
    });
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
      body: SingleChildScrollView(
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
              readOnly: true, // Make the field read-only
            ),
            SizedBox(height: 20),
            TextField(
              controller: _timeIntervalController,
              decoration:
                  InputDecoration(labelText: 'Time Interval Between Dosages'),
            ),
            SizedBox(height: 20),
            Text(
              'Predetermined Times',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _predeterminedTimes.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_predeterminedTimes[index].format(context)),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _removeTime(index),
                  ),
                );
              },
            ),
            TextButton(
              onPressed: _addTime,
              child: Text('Add Time'),
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
