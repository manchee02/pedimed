import 'package:flutter/material.dart';
import 'dart:convert';
import 'database_helper.dart';
import 'package:intl/intl.dart';

class AddMedPage extends StatefulWidget {
  @override
  _AddMedPageState createState() => _AddMedPageState();
}

class _AddMedPageState extends State<AddMedPage> {
  PageController _pageController = PageController(initialPage: 0);
  TextEditingController _activeIngredientController = TextEditingController();
  TextEditingController _brandNameController = TextEditingController();
  TextEditingController _dosageController = TextEditingController();
  TextEditingController _dosagePerDayController = TextEditingController();
  TextEditingController _timeIntervalController = TextEditingController();
  String _doseTimeInterval = '';
  int _selectedProfileId = -1;
  List<Map<String, dynamic>> _profiles = [];
  int _currentPage = 0;
  String _selectedMedicationType = 'Tablet';
  String _selectedDosageUnit = 'MG';
  bool _isDosagePerDaySelected = true;
  List<TimeOfDay> _predeterminedTimes = [];

  final List<String> _medicationTypes = [
    "Tablet",
    "Eyedrop",
    "Liquid",
    "Others",
    "Capsule"
  ];
  final List<String> _dosageUnits = ["MG", "MG/ML", "MG/", "UNT"];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final dbHelper = DatabaseHelper();
    final profiles = await dbHelper.getProfiles();
    setState(() {
      _profiles = profiles;
    });
  }

  void _nextPage() {
    if (_currentPage == 0 && _selectedProfileId == -1) {
      _showErrorDialog('Please select a profile.');
      return;
    }

    if (_currentPage == 1 &&
        (_activeIngredientController.text.isEmpty ||
            _brandNameController.text.isEmpty)) {
      _showErrorDialog('Please enter both active ingredient and brand name.');
      return;
    }

    if (_currentPage == 2 && _selectedMedicationType.isEmpty) {
      _showErrorDialog('Please select a medication type.');
      return;
    }

    if (_currentPage == 3 && _dosageController.text.isEmpty) {
      _showErrorDialog('Please enter the dosage.');
      return;
    }

    if (_currentPage == 4 &&
        ((_isDosagePerDaySelected && _dosagePerDayController.text.isEmpty) ||
            (!_isDosagePerDaySelected &&
                _timeIntervalController.text.isEmpty))) {
      _showErrorDialog(
          'Please enter either dosage per day or time interval between each dosage.');
      return;
    }

    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      _saveMedication();
    }
  }

  void _saveMedication() async {
    // Retrieve the profile name
    final profile = _profiles.firstWhere((p) => p['id'] == _selectedProfileId);
    final profileName = profile['name'];

    List<String> times = _predeterminedTimes.map((time) {
      final now = DateTime.now();
      final parsedTime = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
      return DateFormat.jm().format(parsedTime);
    }).toList();

    Map<String, dynamic> medication = {
      'profileId': _selectedProfileId,
      'profileName': profileName, // Add profile name here
      'activeIngredient': _activeIngredientController.text,
      'brandName': _brandNameController.text,
      'dosage': double.tryParse(_dosageController.text) ?? 0.0,
      'dosageUnit': _selectedDosageUnit,
      'dosagePerDay': _isDosagePerDaySelected
          ? int.tryParse(_dosagePerDayController.text)
          : null,
      'doseTimeInterval':
          !_isDosagePerDaySelected ? _timeIntervalController.text : null,
      'medicationType': _selectedMedicationType,
      'predeterminedTimes': jsonEncode(times),
      'createdAt': DateTime.now().toIso8601String(), // Add createdAt field
    };

    print('Saving Medication: $medication'); // Debug print
    try {
      await DatabaseHelper().insertMedication(medication);
      print('Medication saved successfully'); // Debug print
      Navigator.pop(context);
    } catch (e) {
      print('Error saving medication: $e'); // Debug print for errors
      _showErrorDialog('Failed to save medication: $e');
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

  void _generatePredeterminedTimes() {
    final int dosagePerDay = int.tryParse(_dosagePerDayController.text) ?? 0;
    if (dosagePerDay > 0) {
      final int interval = (16 / dosagePerDay).round();
      setState(() {
        _predeterminedTimes = List.generate(
          dosagePerDay,
          (index) => TimeOfDay(hour: (8 + interval * index) % 24, minute: 0),
        );
      });
    }
  }

  Future<TimeOfDay?> _selectTime(
      BuildContext context, TimeOfDay initialTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    return picked;
  }

  @override
  void dispose() {
    _pageController.dispose();
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
        title: Text('Add Medication'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentPage > 0) {
              _pageController.previousPage(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeIn,
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 10,
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / 5,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildProfileSelectionPage(),
                _buildPage1(),
                _buildMedicationTypePage(),
                _buildPage2(),
                _buildPage3(),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: _nextPage,
              child: Text(_currentPage == 4 ? 'Save' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSelectionPage() {
    return ListView.builder(
      itemCount: _profiles.length,
      itemBuilder: (context, index) {
        final profile = _profiles[index];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedProfileId = profile['id'];
            });
          },
          child: Container(
            padding: EdgeInsets.all(10),
            margin: EdgeInsets.all(5),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${profile['name']}'),
                Text('Age: ${profile['age']}'),
                Text('Allergen: ${profile['allergen']}'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPage1() {
    return Padding(
      padding: EdgeInsets.all(16.0),
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
        ],
      ),
    );
  }

  Widget _buildMedicationTypePage() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Medication Type:', style: TextStyle(fontSize: 16)),
          ..._medicationTypes
              .map((type) => ListTile(
                    title: Text(type),
                    leading: Radio<String>(
                      value: type,
                      groupValue: _selectedMedicationType,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedMedicationType = value!;
                        });
                      },
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _dosageController,
            decoration: InputDecoration(labelText: 'Dosage'),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 20),
          DropdownButton<String>(
            value: _selectedDosageUnit,
            onChanged: (String? newValue) {
              setState(() {
                _selectedDosageUnit = newValue!;
              });
            },
            items: _dosageUnits.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Dosage Input Method:', style: TextStyle(fontSize: 16)),
          ToggleButtons(
            borderColor: Colors.blue,
            fillColor: Colors.blue,
            borderWidth: 2,
            selectedBorderColor: Colors.blue,
            selectedColor: Colors.white,
            color: Colors.blue,
            borderRadius: BorderRadius.circular(8),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Dosage',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Time',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
            onPressed: (int index) {
              setState(() {
                _isDosagePerDaySelected = index == 0;
                if (_isDosagePerDaySelected) {
                  _generatePredeterminedTimes();
                } else {
                  _predeterminedTimes.clear();
                }
              });
            },
            isSelected: [_isDosagePerDaySelected, !_isDosagePerDaySelected],
          ),
          SizedBox(height: 20),
          _isDosagePerDaySelected
              ? Column(
                  children: [
                    TextField(
                      controller: _dosagePerDayController,
                      decoration: InputDecoration(labelText: 'Dosage Per Day'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _generatePredeterminedTimes();
                      },
                    ),
                    SizedBox(height: 20),
                    ..._predeterminedTimes.map((time) {
                      return ListTile(
                        title: Text('Time: ${time.format(context)}'),
                        trailing: IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () async {
                            final newTime = await _selectTime(context, time);
                            if (newTime != null) {
                              setState(() {
                                _predeterminedTimes[_predeterminedTimes
                                    .indexOf(time)] = newTime;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ],
                )
              : Row(
                  children: [
                    Text('Hour: '),
                    Expanded(
                      child: TextField(
                        controller: _timeIntervalController,
                        decoration: InputDecoration(
                            labelText: 'Time Interval Between Dosages'),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
