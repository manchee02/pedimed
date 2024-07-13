import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class IntervalMedicationsSection extends StatefulWidget {
  final List<Map<String, dynamic>> intervalMedications;
  final Map<int, DateTime> medicationTimers;
  final Function(int, String, int) onStartTimer;

  IntervalMedicationsSection({
    required this.intervalMedications,
    required this.medicationTimers,
    required this.onStartTimer,
  });

  @override
  _IntervalMedicationsSectionState createState() =>
      _IntervalMedicationsSectionState();
}

class _IntervalMedicationsSectionState
    extends State<IntervalMedicationsSection> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startUITimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startUITimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours.remainder(24));
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  double _getPercentage(Duration duration, int intervalHours) {
    final totalSeconds = intervalHours * 3600;
    final elapsedSeconds = totalSeconds - duration.inSeconds;
    return elapsedSeconds / totalSeconds;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0),
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interval-Based Medications',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.0),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.intervalMedications.map((med) {
                final intervalHours =
                    int.tryParse(med['doseTimeInterval']) ?? 0;
                final nextDoseTime = widget.medicationTimers[med['id']];
                final isNextDoseAvailable = nextDoseTime != null &&
                    nextDoseTime.isAfter(DateTime.now());

                return Container(
                  width: 250, // Adjust the width to fit both text and timer
                  margin: EdgeInsets.symmetric(horizontal: 8.0),
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 2),
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
                            med['brandName'],
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text('Interval: $intervalHours hours'),
                          if (isNextDoseAvailable)
                            Text(
                              'Next dose at ${DateFormat('hh:mm a').format(nextDoseTime!)}',
                              style: TextStyle(fontSize: 12),
                            ),
                          if (!isNextDoseAvailable)
                            ElevatedButton(
                              onPressed: () {
                                widget.onStartTimer(
                                    med['id'], med['brandName'], intervalHours);
                              },
                              child: Text('Start First Dose',
                                  style: TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                      if (isNextDoseAvailable)
                        CircularPercentIndicator(
                          radius: 40.0,
                          lineWidth: 5.0,
                          percent: _getPercentage(
                            nextDoseTime!.difference(DateTime.now()),
                            intervalHours,
                          ),
                          center: Text(
                            _formatDuration(
                              nextDoseTime!.difference(DateTime.now()),
                            ),
                            style: TextStyle(fontSize: 10),
                          ),
                          progressColor: Colors.green,
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
