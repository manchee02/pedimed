import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'medicine_detail_page.dart';

class MedicineInfoPage extends StatefulWidget {
  @override
  _MedicineInfoPageState createState() => _MedicineInfoPageState();
}

class _MedicineInfoPageState extends State<MedicineInfoPage> {
  TextEditingController _medicineController = TextEditingController();
  String _errorMessage = '';
  List<Map<String, String>> _medicines = [];
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

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

  void _addToSearchHistory(String search) {
    setState(() {
      _searchHistory
          .remove(search); // Remove if it already exists to avoid duplicates
      _searchHistory.insert(0, search); // Insert at the beginning
      if (_searchHistory.length > 10) {
        _searchHistory =
            _searchHistory.sublist(0, 10); // Keep only the last 10 searches
      }
    });
    _saveSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? history = prefs.getStringList('searchHistory');
    if (history != null) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _saveSearchHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('searchHistory', _searchHistory);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medicine Information'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset('assets/openfda.jpg'), // Add the image asset here
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _medicineController,
                decoration: InputDecoration(
                  labelText: 'Enter Medicine Name',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.cancel),
                    onPressed: () {
                      _medicineController.clear();
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final medicineName = _medicineController.text.trim();
                if (medicineName.isNotEmpty) {
                  _addToSearchHistory(medicineName);
                  _fetchMedicineInfo(medicineName);
                } else {
                  setState(() {
                    _medicines = [];
                    _errorMessage = 'Please enter a medicine name.';
                  });
                }
              },
              child: Text('Search', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
            SizedBox(height: 20),
            if (_searchHistory.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _searchHistory.map((search) {
                  return Chip(
                    label: Text(search),
                    onDeleted: () {
                      setState(() {
                        _searchHistory.remove(search);
                        _saveSearchHistory();
                      });
                    },
                  );
                }).toList(),
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
                padding: EdgeInsets.all(8.0),
                itemCount: _medicines.length,
                itemBuilder: (context, index) {
                  final medicine = _medicines[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 8.0),
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text(medicine['name']!),
                      subtitle: Text(
                        'Type: ${medicine['type']}\nBrand: ${medicine['brand']}',
                      ),
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
                    ),
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
