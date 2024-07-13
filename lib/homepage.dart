import 'package:flutter/material.dart';
import 'medi_info.dart';
import 'profile.dart';
import 'add_med.dart';
import 'medicine_store.dart';
import 'medicine_reminder_page.dart';
import 'notification_test_page.dart';
import 'svm_classification_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'upgrade_to_premium_page.dart';

class HomePage extends StatelessWidget {
  final bool permissionGranted;

  HomePage({required this.permissionGranted});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pediatric MedTrack'),
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 50), // Add some spacing above
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMedicineReminderTile(
                          context, 'Medicine Reminder', Icons.alarm),
                      _buildMedicineManagementTile(
                          context, 'Medicine Management', Icons.assignment),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildProfileTile(
                          context, 'Children Profiles', Icons.account_circle),
                      _buildMediInfoTile(
                          context, 'Medicine Information', Icons.info),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                _buildSvmClassificationTile(context, 'SVM Classification',
                    Icons.analytics), // New SVM Classification Tile
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddMedPage()),
          );
        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildTile(BuildContext context, String title, IconData iconData) {
    return Container(
      width: 150,
      height: 150,
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: 50,
            color: Colors.white,
          ),
          SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTile(
      BuildContext context, String title, IconData iconData) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
      },
      child: _buildTile(context, title, iconData),
    );
  }

  Widget _buildMediInfoTile(
      BuildContext context, String title, IconData iconData) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MedicineInfoPage()),
        );
      },
      child: _buildTile(context, title, iconData),
    );
  }

  Widget _buildMedicineManagementTile(
      BuildContext context, String title, IconData iconData) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MedicineStorePage()),
        );
      },
      child: _buildTile(context, title, iconData),
    );
  }

  Widget _buildMedicineReminderTile(
      BuildContext context, String title, IconData iconData) {
    return GestureDetector(
      onTap: () {
        if (permissionGranted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MedicineReminderPage()),
          );
        } else {
          _showPermissionDialog(context);
        }
      },
      child: _buildTile(context, title, iconData),
    );
  }

  Widget _buildSvmClassificationTile(
      BuildContext context, String title, IconData iconData) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  SvmClassificationPage()), // Navigate to the new SVM Classification Page
        );
      },
      child: _buildTile(context, title, iconData),
    );
  }

  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permission Needed'),
          content: Text('Please grant permission to schedule exact alarms.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/pedimed.jpg', height: 80), // App Logo
                SizedBox(height: 10),
                Text(
                  'Navigation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('About Us'),
            onTap: () {
              // Handle About Us tap
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.amber),
                SizedBox(width: 5),
                Text('Upgrade to Premium'),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UpgradeToPremiumPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.schedule),
            title: Text('Schedule Appointment'),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.document_scanner),
            title: Text('Generate Report'),
            onTap: () {
              // Navigate to a mockup page or do nothing
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Scaffold(
                          appBar: AppBar(
                            title: Text('Generate Report'),
                          ),
                          body: Center(
                            child: Text('Generate Report Page (Mockup)'),
                          ),
                        )),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          ListTile(
            leading: Icon(Icons.notification_important),
            title: Text('Test Notification'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationTestPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
