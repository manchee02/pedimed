import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'edit_med.dart';

class MedicineStorePage extends StatefulWidget {
  @override
  _MedicineStorePageState createState() => _MedicineStorePageState();
}

class _MedicineStorePageState extends State<MedicineStorePage> {
  Map<String, List<Map<String, dynamic>>> _medicationsByCategory = {};
  Map<String, List<Map<String, dynamic>>> _medicationsByProfile = {};
  bool _groupByCategory = true;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    final dbHelper = DatabaseHelper();
    final medications = await dbHelper.getMedications();
    final profiles = await dbHelper.getProfiles();

    final Map<String, List<Map<String, dynamic>>> medicationsByCategory = {};
    final Map<String, List<Map<String, dynamic>>> medicationsByProfile = {};

    for (var medication in medications) {
      String category = medication['therapeuticCategory'] ?? 'Unclassified';
      if (!medicationsByCategory.containsKey(category)) {
        medicationsByCategory[category] = [];
      }
      medicationsByCategory[category]!.add(medication);

      String profileName = profiles.firstWhere(
          (profile) => profile['id'] == medication['profileId'],
          orElse: () => {'name': 'Unknown'})['name'];
      if (!medicationsByProfile.containsKey(profileName)) {
        medicationsByProfile[profileName] = [];
      }
      medicationsByProfile[profileName]!.add(medication);
    }

    setState(() {
      _medicationsByCategory = medicationsByCategory;
      _medicationsByProfile = medicationsByProfile;
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
        actions: [
          Switch(
            value: _groupByCategory,
            onChanged: (value) {
              setState(() {
                _groupByCategory = value;
              });
            },
            activeTrackColor: Colors.lightBlueAccent,
            activeColor: Colors.blue,
          ),
        ],
      ),
      body: _medicationsByCategory.isEmpty && _medicationsByProfile.isEmpty
          ? Center(child: Text('No medications added yet.'))
          : ListView(
              children: (_groupByCategory
                      ? _medicationsByCategory.keys
                      : _medicationsByProfile.keys)
                  .map((group) {
                return ExpansionTile(
                  title: Text(group),
                  children: (_groupByCategory
                          ? _medicationsByCategory[group]
                          : _medicationsByProfile[group])!
                      .map((medication) {
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
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  medication['brandName'] ?? '',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Dosage: ${medication['dosage']} ${medication['dosageUnit']}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Active Ingredient: ${medication['activeIngredient']}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Dosage Per Day: ${medication['dosagePerDay'] ?? 'N/A'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Time Interval: ${medication['doseTimeInterval'] ?? 'N/A'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Medication Type: ${medication['medicationType']}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
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
