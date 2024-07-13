import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpgradeToPremiumPage extends StatefulWidget {
  @override
  _UpgradeToPremiumPageState createState() => _UpgradeToPremiumPageState();
}

class _UpgradeToPremiumPageState extends State<UpgradeToPremiumPage> {
  bool isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isSubscribed = prefs.getBool('isSubscribed') ?? false;
    });
  }

  Future<void> _toggleSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isSubscribed = !isSubscribed;
      prefs.setBool('isSubscribed', isSubscribed);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSubscribed ? 'Subscribed' : 'Unsubscribed'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upgrade to Premium'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 40.0),
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 40),
                        Text(
                          'UPGRADE TO PREMIUM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'RM9/Month',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          '- Up to 15 children/dependents profiles\n- Generate Medical Adherence Report\n- Scheduling Appointments',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.blue,
                      child: Icon(
                        Icons.star,
                        color: Colors.yellow,
                        size: 40,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: _toggleSubscription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSubscribed ? Colors.yellow : Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: TextStyle(fontSize: 18),
                ),
                child: Text(
                  isSubscribed ? 'Unsubscribe' : 'Upgrade',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
