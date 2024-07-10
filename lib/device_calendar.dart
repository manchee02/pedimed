import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class CalendarPermissionWidget extends StatefulWidget {
  @override
  _CalendarPermissionWidgetState createState() =>
      _CalendarPermissionWidgetState();
}

class _CalendarPermissionWidgetState extends State<CalendarPermissionWidget> {
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
  }

  Future<void> _requestCalendarPermissions() async {
    var status = await Permission.calendar.status;
    if (status.isDenied) {
      if (await Permission.calendar.request().isGranted) {
        // Permission granted
      } else {
        // Permission denied
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calendar permission is required to set reminders.'),
          ),
        );
      }
    } else if (status.isPermanentlyDenied) {
      // Handle permanently denied permission
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Calendar permission is permanently denied. Please enable it from settings.'),
        ),
      );
      openAppSettings();
    }
  }

  Future<void> _createCalendarEvent(String title, String description,
      DateTime startTime, DateTime endTime) async {
    final permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
    if (permissionsGranted.isSuccess && permissionsGranted.data!) {
      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      final calendar =
          calendarsResult.data!.firstWhere((c) => c.isDefault == true);

      final tz.TZDateTime start = tz.TZDateTime.from(startTime, tz.local);
      final tz.TZDateTime end = tz.TZDateTime.from(endTime, tz.local);

      final event = Event(
        calendar.id,
        title: title,
        description: description,
        start: start,
        end: end,
      );
      await _deviceCalendarPlugin.createOrUpdateEvent(event);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar Permission Example'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _requestCalendarPermissions,
          child: Text('Request Calendar Permission'),
        ),
      ),
    );
  }
}
