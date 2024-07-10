import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'edit_med.dart';

class MedicineStorePage extends StatefulWidget {
  @override
  _MedicineStorePageState createState() => _MedicineStorePageState();
}

class _MedicineStorePageState extends State<MedicineStorePage> {
  Map<String, List<Map<String, dynamic>>> _medicationsByCategory = {};

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    final dbHelper = DatabaseHelper();
    final medications = await dbHelper.getMedications();
    final Map<String, List<Map<String, dynamic>>> medicationsByCategory = {};

    for (var medication in medications) {
      String category = medication['therapeuticCategory'] ?? 'Unclassified';
      if (!medicationsByCategory.containsKey(category)) {
        medicationsByCategory[category] = [];
      }
      medicationsByCategory[category]!.add(medication);
    }

    setState(() {
      _medicationsByCategory = medicationsByCategory;
    });
  }

  Future<void> _deleteMedication(int id) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.deleteMedication(id);
    _loadMedications(); // Refresh the list after deletion
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medicine Management'),
      ),
      body: _medicationsByCategory.isEmpty
          ? Center(child: Text('No medications added yet.'))
          : ListView(
              children: _medicationsByCategory.keys.map((category) {
                return ExpansionTile(
                  title: Text(category),
                  children: _medicationsByCategory[category]!.map((medication) {
                    return Container(
                      margin:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                medication['brandName'] ?? '',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Dosage: ${medication['dosage']} ${medication['dosageUnit']}',
                              ),
                              Text(
                                'Active Ingredient: ${medication['activeIngredient']}',
                              ),
                              Text(
                                'Dosage Per Day: ${medication['dosagePerDay'] ?? 'N/A'}',
                              ),
                              Text(
                                'Time Interval: ${medication['doseTimeInterval'] ?? 'N/A'}',
                              ),
                              Text(
                                'Medication Type: ${medication['medicationType']}',
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditMedicationPage(
                                    medication: medication,
                                  ),
                                ),
                              ).then((_) => _loadMedications());
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _deleteMedication(medication['id']);
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
    );
  }
}
