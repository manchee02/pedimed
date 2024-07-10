import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'medicine_detail_page.dart';

class MedicineInfoPage extends StatefulWidget {
  @override
  _MedicineInfoPageState createState() => _MedicineInfoPageState();
}

class _MedicineInfoPageState extends State<MedicineInfoPage> {
  TextEditingController _medicineController = TextEditingController();
  String _errorMessage = '';
  List<Map<String, String>> _medicines = [];

  // Define your API key here
  final String apiKey = 'aYMuR9q7cYCFoBR73Pguh62pRccNm7WFrcqYAnfy';

  Future<void> _fetchMedicineInfo(String medicineName) async {
    try {
      bool isParacetamol = medicineName.toLowerCase() == 'paracetamol';
      String searchName = isParacetamol ? 'Acetaminophen' : medicineName;

      final String apiUrl =
          'https://api.fda.gov/drug/label.json?search=openfda.brand_name:"$searchName"';

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('API Response: $jsonData'); // Log the response for debugging
        if (jsonData['results'] != null && jsonData['results'].isNotEmpty) {
          _processResults(jsonData['results']);
        } else if (isParacetamol) {
          // Try searching for "Acetaminophen" explicitly if "Paracetamol" yields no results
          final alternativeApiUrl =
              'https://api.fda.gov/drug/label.json?search=openfda.brand_name:Acetaminophen';

          final alternativeResponse = await http.get(
            Uri.parse(alternativeApiUrl),
            headers: {
              'Accept': 'application/json',
            },
          );

          if (alternativeResponse.statusCode == 200) {
            final alternativeJsonData = json.decode(alternativeResponse.body);
            print(
                'Alternative API Response: $alternativeJsonData'); // Log the response for debugging
            if (alternativeJsonData['results'] != null &&
                alternativeJsonData['results'].isNotEmpty) {
              _processResults(alternativeJsonData['results']);
            } else {
              setState(() {
                _medicines = [];
                _errorMessage = 'Medicine not found.';
              });
            }
          } else {
            setState(() {
              _medicines = [];
              _errorMessage =
                  'Failed to fetch data. Status Code: ${alternativeResponse.statusCode}';
            });
          }
        } else {
          setState(() {
            _medicines = [];
            _errorMessage = 'Medicine not found.';
          });
        }
      } else {
        setState(() {
          _medicines = [];
          _errorMessage =
              'Failed to fetch data. Status Code: ${response.statusCode}';
        });
      }
    } catch (error) {
      print('Error fetching medicine information: $error');
      setState(() {
        _medicines = [];
        _errorMessage = 'Error fetching medicine information: $error';
      });
    }
  }

  void _processResults(List<dynamic> results) {
    List<Map<String, String>> medicines = [];
    for (var result in results) {
      String name = result['openfda']?['brand_name']?.first ?? 'Not Available';
      String type = result['dosage_form'] ?? 'Not Available';
      String brand = result['openfda']?['brand_name']?.first ?? 'Not Available';
      String id = result['id'] ?? 'Not Available';
      medicines.add({
        'name': name,
        'type': type,
        'brand': brand,
        'id': id,
      });
    }
    setState(() {
      _medicines = medicines;
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medicine Information'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _medicineController,
              decoration: InputDecoration(
                labelText: 'Enter Medicine Name',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final medicineName = _medicineController.text.trim();
                if (medicineName.isNotEmpty) {
                  _fetchMedicineInfo(medicineName);
                } else {
                  setState(() {
                    _medicines = [];
                    _errorMessage = 'Please enter a medicine name.';
                  });
                }
              },
              child: Text('Search'),
            ),
            SizedBox(height: 20),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _medicines.length,
                itemBuilder: (context, index) {
                  final medicine = _medicines[index];
                  return ListTile(
                    title: Text(medicine['name']!),
                    subtitle: Text(
                        'Type: ${medicine['type']}\nBrand: ${medicine['brand']}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MedicineDetailPage(
                            medicineName: medicine['name']!,
                            medicineId: medicine['id']!,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
