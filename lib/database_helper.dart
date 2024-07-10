import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;
import 'main.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'profiles.db');
    return await openDatabase(
      path,
      version: 9, // Increment the version number
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 9) {
          await _updateTables(db, oldVersion, newVersion);
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute(
      "CREATE TABLE IF NOT EXISTS profiles(id INTEGER PRIMARY KEY, name TEXT, age TEXT, allergen TEXT)",
    );
    await db.execute(
      "CREATE TABLE IF NOT EXISTS medications(id INTEGER PRIMARY KEY, profileId INTEGER, profileName TEXT, activeIngredient TEXT, brandName TEXT, dosage NUMERIC, dosageUnit TEXT, dosagePerDay INTEGER, doseTimeInterval TEXT, medicationType TEXT, predeterminedTimes TEXT, therapeuticCategory TEXT DEFAULT 'Unclassified')",
    );
    await db.execute(
      "CREATE TABLE IF NOT EXISTS medication_taken(id INTEGER PRIMARY KEY AUTOINCREMENT, medicationId INTEGER, timestamp TEXT)",
    );
  }

  Future<void> _updateTables(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 9) {
      // Add profileName column to medications table if it doesn't exist
      await db.execute(
        "ALTER TABLE medications ADD COLUMN profileName TEXT",
      );
      // Add therapeuticCategory column to medications table if it doesn't exist
      await db.execute(
        "ALTER TABLE medications ADD COLUMN therapeuticCategory TEXT DEFAULT 'Unclassified'",
      );
    }
  }

  Future<List<Map<String, dynamic>>> getProfiles() async {
    final db = await database;
    return await db.query('profiles');
  }

  Future<void> insertProfile(Map<String, dynamic> profile) async {
    final db = await database;
    await db.insert('profiles', profile);
  }

  Future<void> updateProfile(Map<String, dynamic> profile) async {
    final db = await database;
    await db.update(
      'profiles',
      profile,
      where: 'id = ?',
      whereArgs: [profile['id']],
    );
  }

  Future<void> deleteProfile(int id) async {
    final db = await database;
    await db.delete(
      'profiles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> insertMedication(Map<String, dynamic> medication) async {
    final db = await database;
    try {
      await db.insert('medications', medication);
      print('Medication inserted successfully: $medication');
      await _scheduleNotificationsForMedication(medication);
    } catch (e) {
      print('Error inserting medication: $e');
    }
  }

  Future<void> _scheduleNotificationsForMedication(
      Map<String, dynamic> medication) async {
    final List<dynamic> predeterminedTimes =
        jsonDecode(medication['predeterminedTimes']);
    for (var time in predeterminedTimes) {
      final DateTime scheduledTime = _parseTime(time);
      print('Scheduling notification for time: $scheduledTime');
      await _scheduleNotification(
        medication.hashCode + time.hashCode,
        'Medication Reminder',
        'It\'s time for ${medication['profileName']} to take ${medication['brandName']} medication.',
        scheduledTime,
      );
    }
  }

  Future<void> _scheduleNotification(
      int id, String title, String body, DateTime scheduledTime) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'medication_channel',
      'Medication Reminders',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    print('Scheduling notification with id: $id at $scheduledTime');
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  DateTime _parseTime(String time) {
    final DateFormat format = DateFormat.jm(); // 12-hour format with AM/PM
    final DateTime now = DateTime.now();
    final DateTime parsedTime = format.parse(time);
    return DateTime(
        now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
  }

  Future<List<Map<String, dynamic>>> getMedications() async {
    final db = await database;
    return await db.query('medications');
  }

  Future<void> deleteMedication(int id) async {
    final db = await database;
    await db.delete(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> recordMedicineTaken(int medicationId, String timestamp) async {
    final db = await database;
    await db.insert('medication_taken', {
      'medicationId': medicationId,
      'timestamp': timestamp,
    });
  }

  Future<void> updateMedication(Map<String, dynamic> medication) async {
    final db = await database;
    await db.update(
      'medications',
      medication,
      where: 'id = ?',
      whereArgs: [medication['id']],
    );
  }

  Future<Map<String, dynamic>?> getProfileById(int id) async {
    final db = await database;
    final result = await db.query(
      'profiles',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>> getMedicationById(int id) async {
    final db = await database;
    final result = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty
        ? result.first
        : throw Exception('Medication not found');
  }

  Future<List<Map<String, dynamic>>> getMedicationTakenTimes(
      int medicationId, String startTime, String endTime) async {
    final db = await database;
    final result = await db.query(
      'medication_taken',
      where: 'medicationId = ? AND timestamp BETWEEN ? AND ?',
      whereArgs: [medicationId, startTime, endTime],
    );
    return result;
  }

  Future<void> updateMedicationCategory(int id, String category) async {
    final db = await database;
    await db.update(
      'medications',
      {'therapeuticCategory': category},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> logTableSchema() async {
    final db = await database;
    final profilesSchema = await db.rawQuery("PRAGMA table_info(profiles)");
    final medicationsSchema =
        await db.rawQuery("PRAGMA table_info(medications)");
    final medicationTakenSchema =
        await db.rawQuery("PRAGMA table_info(medication_taken)");
    print('Profiles table schema: $profilesSchema');
    print('Medications table schema: $medicationsSchema');
    print('Medication taken table schema: $medicationTakenSchema');
  }
}
