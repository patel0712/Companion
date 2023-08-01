import 'package:companion/menu/settings.dart';
import 'package:companion/menu/profile.dart';
import 'package:companion/screens/GenerateQRCode.dart';
import 'package:flutter/material.dart';
import 'package:companion/utils/user_service.dart';
import '../utils/auth_service.dart';

class MenuDrawer extends StatelessWidget {
  final UserService userService = UserService();
  AuthService authService = AuthService();

  Future<Map<String, dynamic>?> getUserData() async {
    Map<String, dynamic>? userData = await userService.fetchCurrentUserData();
    return userData;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: FutureBuilder<Map<String, dynamic>?>(
                    future: getUserData(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        // Data retrieved successfully
                        // Access the fields from userData
                        String? name = snapshot.data?['name'];
                        String? patientId = snapshot.data?['patientId'];
                        String? phone = snapshot.data?['phone'];
                        String? imageUrl = snapshot.data?['avatar_url'];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(imageUrl!),
                            ),
                            SizedBox(height: 10),
                            Text(
                              name ?? 'Unknown',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              userService.getCurrentUserEmail()!,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        );
                      } else if (snapshot.hasError) {
                        // Handle the error case
                        return Text('Something went wrong');
                      } else {
                        // Data retrieval is still in progress
                        // Display a loading indicator
                        return CircularProgressIndicator();
                      }
                    },
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.person,
                    color: Colors.blue,
                  ),
                  title: Text('Profile'),
                  onTap: () {
                    // Handle profile tab tap
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileEditPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 3.0),
                    child: Image.asset(
                      'assets/caretaker.png',
                      color: Colors.blue,
                      scale: 5.0,
                      height: 20.0,
                      width: 20.0,
                    ),
                  ),
                  title: Text('Care Giver'),
                  onTap: () {
                    // Handle Care Taker tap
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => GenerateQRCode()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.settings,
                    color: Colors.blue,
                  ),
                  title: Text('Settings'),
                  onTap: () {
                    // Handle settings tab tap
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsPage()),
                    );
                  },
                ),
              ],
            ),
          ),
          Divider(), // Add a divider before the bottom options
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Colors.blue,
            ),
            title: Text('Logout'),
            onTap: () {
              // Handle logout tap
              authService.logout();
            },
          ),
        ],
      ),
    );
  }
}
