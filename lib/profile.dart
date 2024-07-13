import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _ageController = TextEditingController();
  TextEditingController _allergenController = TextEditingController();

  List<Map<String, dynamic>> _profiles = [];
  DatabaseHelper _dbHelper = DatabaseHelper();
  bool isPremiumUser = false;
  final int basicProfileLimit = 5;
  final int premiumProfileLimit = 15;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _loadSubscriptionStatus();
  }

  Future<void> _loadProfiles() async {
    List<Map<String, dynamic>> profiles = await _dbHelper.getProfiles();
    setState(() {
      _profiles = profiles;
    });
  }

  Future<void> _loadSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isPremiumUser = prefs.getBool('isSubscribed') ?? false;
    });
  }

  void _addProfile() async {
    String name = _nameController.text;
    String age = _ageController.text;
    String? allergen = _allergenController.text;

    int profileLimit = isPremiumUser ? premiumProfileLimit : basicProfileLimit;

    if (_profiles.length >= profileLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upgrade to premium to add more profiles.')),
      );
      return;
    }

    if (name.isNotEmpty && age.isNotEmpty) {
      Map<String, dynamic> profile = {
        'name': name,
        'age': age,
        'allergen': allergen,
      };
      await _dbHelper.insertProfile(profile);

      // Clear text controllers
      _nameController.clear();
      _ageController.clear();
      _allergenController.clear();

      // Reload profiles
      _loadProfiles();
    }
  }

  void _editProfile(int id) async {
    // Find the profile with the given id
    Map<String, dynamic> profile = _profiles.firstWhere((p) => p['id'] == id);

    // Your existing code for showing the edit dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        _nameController.text = profile['name'] ?? '';
        _ageController.text = profile['age'] ?? '';
        _allergenController.text = profile['allergen'] ?? '';

        return AlertDialog(
          title: Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _ageController,
                decoration: InputDecoration(labelText: 'Age'),
              ),
              TextField(
                controller: _allergenController,
                decoration: InputDecoration(labelText: 'Allergen'),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                Map<String, dynamic> updatedProfile = {
                  'id': profile['id'],
                  'name': _nameController.text,
                  'age': _ageController.text,
                  'allergen': _allergenController.text,
                };
                await _dbHelper.updateProfile(updatedProfile);
                Navigator.of(context).pop();
                _loadProfiles();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteProfile(int id) async {
    List<Map<String, dynamic>> medications =
        await _dbHelper.getMedicationsForProfile(id);

    if (medications.isNotEmpty) {
      _showDeleteMedicationsAlert();
    } else {
      await _dbHelper.deleteProfile(id);
      _loadProfiles();
    }
  }

  void _showDeleteMedicationsAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cannot delete profile'),
          content: Text('Delete the medications linked to this profile first.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Profiles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Column(
              children: _profiles.map((profile) {
                return Container(
                  margin: EdgeInsets.only(bottom: 10.0),
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    title: Text(profile['name'] ?? ''),
                    subtitle: Text(
                      'Age: ${profile['age']}, Allergen: ${profile['allergen']}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            _editProfile(profile['id']);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _deleteProfile(profile['id']);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Add Profile'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(labelText: 'Name'),
                          ),
                          TextField(
                            controller: _ageController,
                            decoration: InputDecoration(labelText: 'Age'),
                          ),
                          TextField(
                            controller: _allergenController,
                            decoration: InputDecoration(labelText: 'Allergen'),
                          ),
                        ],
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _addProfile();
                          },
                          child: Text('Add'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('Add Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
