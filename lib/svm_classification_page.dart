import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'database_helper.dart';
import 'preprocess_data.dart';

class SvmClassificationPage extends StatefulWidget {
  @override
  _SvmClassificationPageState createState() => _SvmClassificationPageState();
}

class _SvmClassificationPageState extends State<SvmClassificationPage> {
  late Future<List<Map<String, dynamic>>> _medicinesFuture;
  String predictionResult = '';
  Map<String, dynamic>? selectedMedicine;
  String? selectedMedicineName;

  @override
  void initState() {
    super.initState();
    _medicinesFuture = _fetchMedicines();
  }

  Future<List<Map<String, dynamic>>> _fetchMedicines() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    return await dbHelper.getMedications();
  }

  Future<void> _predictMedicineCategory() async {
    if (selectedMedicine == null) {
      setState(() {
        predictionResult = 'Please select a medicine first.';
      });
      return;
    }

    try {
      Map<String, dynamic>? preprocessedData =
          await preprocessData(selectedMedicine!);
      if (preprocessedData == null) {
        setState(() {
          predictionResult = 'Error in preprocessing data.';
        });
        return;
      }
      final response = await http.post(
        Uri.parse('http://10.62.50.120:5000/predict'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(preprocessedData),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          if (result['confidence'] < 50) {
            predictionResult = 'Error: Confidence level is below 50%.';
          } else if (result['category'] == null) {
            predictionResult = 'Error: Medicine is not within scope.';
          } else {
            predictionResult =
                'Category: ${result['category']}\nConfidence: ${result['confidence']}%';
          }
        });
      } else {
        throw Exception('Failed to get prediction');
      }
    } catch (e) {
      setState(() {
        predictionResult = 'Error: $e';
      });
    }
  }

  Future<void> _savePrediction() async {
    if (selectedMedicine == null || predictionResult.contains('Error')) {
      setState(() {
        predictionResult = 'Cannot save. Please ensure a valid prediction.';
      });
      return;
    }

    final categoryMatch =
        RegExp(r'Category: (.+?)\n').firstMatch(predictionResult);
    final category =
        categoryMatch != null ? categoryMatch.group(1) : 'Unclassified';

    DatabaseHelper dbHelper = DatabaseHelper();
    await dbHelper.updateMedicationCategory(selectedMedicine!['id'], category!);
    setState(() {
      predictionResult = 'Prediction saved successfully.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SVM Classification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select a Medicine',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _medicinesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error fetching medicines'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No medicines found'));
                } else {
                  return DropdownButton<String>(
                    hint: Text('Select a Medicine'),
                    value: selectedMedicineName,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedMedicineName = newValue;
                        selectedMedicine = snapshot.data!.firstWhere(
                          (medicine) => medicine['brandName'] == newValue,
                        );
                      });
                    },
                    items: snapshot.data!
                        .map<DropdownMenuItem<String>>((medicine) {
                      return DropdownMenuItem<String>(
                        value: medicine['brandName'],
                        child: Text(
                            '${medicine['brandName']} (${medicine['activeIngredient']})'),
                      );
                    }).toList(),
                  );
                }
              },
            ),
            SizedBox(height: 10),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _predictMedicineCategory,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue),
                      child: Text('Predict Category'),
                    ),
                  ),
                  SizedBox(height: 10),
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          predictionResult,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _savePrediction,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue),
                      child: Text('Save Prediction'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
