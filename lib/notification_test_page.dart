import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationTestPage extends StatefulWidget {
  @override
  _NotificationTestPageState createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    if (await Permission.notification.isGranted) {
      return;
    }
    final status = await Permission.notification.request();
    if (!status.isGranted) {
      print('Notification permission not granted');
    }
  }

  Future<void> _showImmediateNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'medication_channel',
      'Medication Reminders',
      channelDescription: 'Channel for medication reminders',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    print('Showing immediate notification');
    await flutterLocalNotificationsPlugin.show(
      0,
      'Immediate Test Notification',
      'This is an immediate test notification',
      platformChannelSpecifics,
    );
  }

  Future<void> _scheduleNotification() async {
    Workmanager().registerOneOffTask(
      'uniqueName',
      'simpleTask',
      initialDelay: Duration(seconds: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _showImmediateNotification,
              child: Text('Show Immediate Notification'),
            ),
            ElevatedButton(
              onPressed: _scheduleNotification,
              child: Text('Show Notification after 10 Seconds'),
            ),
          ],
        ),
      ),
    );
  }
}
