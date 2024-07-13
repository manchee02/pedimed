import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MedicineDetailPage extends StatefulWidget {
  final String medicineName;
  final String medicineId;

  MedicineDetailPage({required this.medicineName, required this.medicineId});

  @override
  _MedicineDetailPageState createState() => _MedicineDetailPageState();
}

class _MedicineDetailPageState extends State<MedicineDetailPage> {
  String _activeIngredient = '';
  List<String> _dosage = [];
  String _usage = '';
  List<String> _indications = [];
  String _pediatricDosage = '';
  String _adultDosage = '';
  String _errorMessage = '';
  bool _showPediatric = false;

  @override
  void initState() {
    super.initState();
    _fetchDetailedInfo(widget.medicineId);
  }

  Future<void> _fetchDetailedInfo(String medicineId) async {
    final String apiUrl =
        'https://api.fda.gov/drug/label.json?search=id:$medicineId';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['results'] != null && jsonData['results'].isNotEmpty) {
          final result = jsonData['results'].first;
          String activeIngredient =
              result['active_ingredient']?.join(', ') ?? 'Not Available';
          List<String> dosage = _extractSegments(
              result['dosage_and_administration']?.first ?? '');
          String usage = result['purpose']?.first ?? 'Not Available';
          List<String> indications =
              _extractSegments(result['indications_and_usage']?.first ?? '');

          // Example parsing for pediatric and adult dosages (this depends on actual data structure)
          String pediatricDosage =
              _extractSpecificDosage(dosage.join(' '), 'Pediatric');
          String adultDosage =
              _extractSpecificDosage(dosage.join(' '), 'Adult');

          if (mounted) {
            setState(() {
              _activeIngredient = activeIngredient;
              _dosage = dosage;
              _usage = usage;
              _indications = indications;
              _pediatricDosage = pediatricDosage;
              _adultDosage = adultDosage;
              _errorMessage = '';
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _activeIngredient = '';
              _dosage = [];
              _usage = '';
              _indications = [];
              _pediatricDosage = '';
              _adultDosage = '';
              _errorMessage = 'Detailed information not found.';
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _activeIngredient = '';
            _dosage = [];
            _usage = '';
            _indications = [];
            _pediatricDosage = '';
            _adultDosage = '';
            _errorMessage =
                'Failed to fetch data. Status Code: ${response.statusCode}';
          });
        }
      }
    } catch (error) {
      print('Error fetching detailed medicine information: $error');
      if (mounted) {
        setState(() {
          _activeIngredient = '';
          _dosage = [];
          _usage = '';
          _indications = [];
          _pediatricDosage = '';
          _adultDosage = '';
          _errorMessage =
              'Error fetching detailed medicine information: $error';
        });
      }
    }
  }

  String _extractSpecificDosage(String text, String type) {
    if (type == 'Pediatric') {
      return text.contains('Pediatric') ? text : 'Not Available';
    } else {
      return text.contains('Adult') ? text : 'Not Available';
    }
  }

  List<String> _extractSegments(String text) {
    List<String> segments = [];
    RegExp regExp = RegExp(r'(?<!\()\d+\.\d+(?![\)])');
    Iterable<Match> matches = regExp.allMatches(text);
    int lastIndex = 0;

    for (Match match in matches) {
      if (lastIndex != match.start) {
        segments.add(text.substring(lastIndex, match.start).trim());
      }
      lastIndex = match.start;
    }
    segments.add(text.substring(lastIndex).trim());
    return segments;
  }

  List<Widget> _buildCollapsibleText(List<String> texts) {
    return texts
        .asMap()
        .map((index, text) {
          return MapEntry(
            index,
            ExpansionTile(
              title: Text(
                text.split(' ').take(4).join(' ') + '...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(text),
                )
              ],
            ),
          );
        })
        .values
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medicine Detail'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.medicineName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            if (_errorMessage.isEmpty) ...[
              Text(
                'Active Ingredient:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(_activeIngredient),
              SizedBox(height: 20),
              Text(
                'Indications:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._buildCollapsibleText(_indications),
              SizedBox(height: 20),
              Text(
                'Usage:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._buildCollapsibleText([_usage]),
              SizedBox(height: 20),
              Text(
                'Dosage:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._buildCollapsibleText(_dosage),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showPediatric = true;
                      });
                    },
                    child: Text('Pediatric Dosage'),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showPediatric = false;
                      });
                    },
                    child: Text('Adult Dosage'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (_showPediatric)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Pediatric Dosage:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ..._buildCollapsibleText([_pediatricDosage]),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Adult Dosage:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ..._buildCollapsibleText([_adultDosage]),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}
