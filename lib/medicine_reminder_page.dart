import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'database_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'interval_medications_section.dart';

class MedicineReminderPage extends StatefulWidget {
  @override
  _MedicineReminderPageState createState() => _MedicineReminderPageState();
}

class _MedicineReminderPageState extends State<MedicineReminderPage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> intervalMedications = [];
  Map<int, DateTime> medicationTimers = {};

  @override
  void initState() {
    super.initState();
    _loadTimers();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    final medications = await _databaseHelper.getMedications();
    setState(() {
      intervalMedications = medications
          .where((med) =>
              med['doseTimeInterval'] != null &&
              med['doseTimeInterval'].isNotEmpty)
          .toList();
    });
  }

  Future<void> _loadTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    setState(() {
      for (var key in keys) {
        final timeStr = prefs.getString(key);
        if (timeStr != null) {
          medicationTimers[int.parse(key)] = DateTime.parse(timeStr);
        }
      }
    });
  }

  Future<void> _recordMedicineTaken(
      int medicationId, String time, String medicationName) async {
    final timestamp = DateTime.now();
    final formattedTime = DateFormat('hh:mm a').format(timestamp);
    await _databaseHelper.recordMedicineTaken(
        medicationId, timestamp.toIso8601String());
    await _firestore.collection('medication_taken').add({
      'medicationId': medicationId,
      'medicationName': medicationName,
      'timeTaken': formattedTime,
      'dateTaken': DateFormat('yyyy-MM-dd').format(timestamp),
      'timestamp': timestamp.toIso8601String(),
    });
    setState(() {});
  }

  Future<void> _startTimer(
      int medicationId, String medicationName, int intervalHours) async {
    final now = DateTime.now();
    final nextDoseTime = now.add(Duration(hours: intervalHours));
    medicationTimers[medicationId] = nextDoseTime;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        medicationId.toString(), nextDoseTime.toIso8601String());

    await scheduleNotification(
      medicationId,
      'Medication Reminder',
      'It\'s time for your next dose of $medicationName',
      nextDoseTime,
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medicine Reminder'),
      ),
      body: Column(
        children: [
          _buildCalendarHeader(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _databaseHelper.getMedications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No medications found'));
                }

                final medications = snapshot.data!;
                final groupedMedications = _groupMedicationsByTime(medications);
                final sortedTimes = groupedMedications.keys.toList()
                  ..sort((a, b) => DateFormat.jm()
                      .parse(a)
                      .compareTo(DateFormat.jm().parse(b)));

                return ListView.builder(
                  itemCount: sortedTimes.length,
                  itemBuilder: (context, index) {
                    final time = sortedTimes[index];
                    final meds = groupedMedications[time]!;
                    return _buildMedicationGroup(time, meds);
                  },
                );
              },
            ),
          ),
          IntervalMedicationsSection(
            intervalMedications: intervalMedications,
            medicationTimers: medicationTimers,
            onStartTimer: _startTimer,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (index) {
              final date = DateTime.now()
                  .subtract(Duration(days: DateTime.now().weekday - 1 - index));
              final isSelected = _selectedDate.day == date.day;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      DateFormat('E').format(date),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          Text(
            'Today, ${DateFormat.yMMMEd().format(_selectedDate)}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingTile() {
    return ListTile(
      title: const Text('Loading...'),
    );
  }

  Widget _buildErrorTile(String error) {
    return ListTile(
      title: Text('Error: $error'),
    );
  }

  Widget _buildDefaultTile(Map<String, dynamic> medication) {
    return ListTile(
      title: Text(medication['brandName']),
      trailing: Text('${medication['dosage']} ${medication['dosageUnit']}'),
    );
  }

  Widget _buildMedicationTile(
      Map<String, dynamic> medication,
      Map<String, dynamic> profile,
      String time,
      bool taken,
      String? takenTime) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10),
          color: taken ? Colors.blue[100] : Colors.white,
        ),
        child: ListTile(
          leading: Image.asset(
            'assets/${medication['medicationType'].toLowerCase()}.jpg',
            width: 40,
            height: 40,
          ),
          title: Text(
            medication['brandName'],
            style: taken ? TextStyle(color: Colors.blue) : null,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Child: ${profile['name']}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (taken)
                Text('Taken at $takenTime',
                    style: TextStyle(color: Colors.blue)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${medication['dosage']} ${medication['dosageUnit']}'),
              SizedBox(width: 8),
              IconButton(
                icon:
                    Icon(Icons.check, color: taken ? Colors.blue : Colors.grey),
                onPressed: taken
                    ? null
                    : () {
                        _recordMedicineTaken(
                                medication['id'], time, medication['brandName'])
                            .then((_) {
                          setState(() {});
                        });
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicationGroup(String time, List<Map<String, dynamic>> meds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            time,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ...meds.map((medication) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: _databaseHelper.getProfileById(medication['profileId']),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingTile();
              } else if (profileSnapshot.hasError) {
                return _buildErrorTile(profileSnapshot.error.toString());
              } else if (!profileSnapshot.hasData) {
                return _buildDefaultTile(medication);
              }

              final profile = profileSnapshot.data!;
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: _databaseHelper.getMedicationTakenTimes(
                    medication['id'],
                    DateFormat('yyyy-MM-dd').format(_selectedDate) +
                        'T00:00:00',
                    DateFormat('yyyy-MM-dd').format(_selectedDate) +
                        'T23:59:59'),
                builder: (context, takenSnapshot) {
                  bool taken = false;
                  String? takenTime;
                  if (takenSnapshot.connectionState == ConnectionState.done &&
                      takenSnapshot.hasData) {
                    taken = takenSnapshot.data!.any((takenMed) {
                      final takenTimestamp =
                          DateTime.parse(takenMed['timestamp']);
                      takenTime = DateFormat('hh:mm a').format(takenTimestamp);
                      return DateFormat.jm().format(takenTimestamp) == time;
                    });
                  }
                  return _buildMedicationTile(
                      medication, profile, time, taken, takenTime);
                },
              );
            },
          );
        }).toList(),
      ],
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupMedicationsByTime(
      List<Map<String, dynamic>> medications) {
    final Map<String, List<Map<String, dynamic>>> groupedMedications = {};

    for (var med in medications) {
      if (med['doseTimeInterval'] != null &&
          med['doseTimeInterval'].isNotEmpty) {
        continue;
      }
      final doseTimeInterval = med['doseTimeInterval'] ?? '';
      final predeterminedTimes = med['predeterminedTimes'] != null
          ? List<String>.from(jsonDecode(med['predeterminedTimes']))
          : [];
      final times = predeterminedTimes.isNotEmpty
          ? predeterminedTimes
          : (doseTimeInterval.isNotEmpty
              ? _calculateIntervalTimes(doseTimeInterval)
              : ['No time specified']);

      for (var time in times) {
        if (!groupedMedications.containsKey(time)) {
          groupedMedications[time] = [];
        }
        if (!groupedMedications[time]!.any((m) => m['id'] == med['id'])) {
          groupedMedications[time]!.add(med);
        }
      }
    }

    return groupedMedications;
  }

  List<String> _calculateIntervalTimes(String doseTimeInterval) {
    final intervalInHours = int.tryParse(doseTimeInterval) ?? 0;
    if (intervalInHours <= 0) return ['No time specified'];

    final times = <String>[];
    final now = DateTime.now();
    var nextTime = DateTime(now.year, now.month, now.day, 8, 0);

    while (nextTime.day == now.day) {
      times.add(DateFormat.jm().format(nextTime));
      nextTime = nextTime.add(Duration(hours: intervalInHours));
    }

    return times;
  }
}
