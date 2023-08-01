import 'package:flutter/material.dart';
import 'package:companion/utils/user_service.dart';
import 'package:local_auth/local_auth.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _enableBiometrics = false;
  bool _isAuthenticated = false;
  bool _darkModeEnabled = false; // Track the dark mode state

  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    getBiometricPreference(); // Retrieve the biometric preference when the settings page is initialized
  }

  void getBiometricPreference() async {
    bool isBiometricEnabled =
        await BiometricPreferenceManager().getBiometricPreference();
    setState(() {
      _enableBiometrics = isBiometricEnabled;
    });
  }

  Future<void> authenticateWithBiometrics() async {
    bool isBiometricEnabled =
        await BiometricPreferenceManager().getBiometricPreference();

    if (!isBiometricEnabled) {
      // Biometric login is disabled, handle the login flow accordingly (e.g., show traditional login options).
      return;
    }

    bool isAuthenticated = false;
    try {
      isAuthenticated = await auth.authenticate(
        localizedReason: 'Authenticate to access the app',
        // biometricOnly: true,
      );
    } catch (e) {
      // Handle any errors that occurred during biometric authentication
      print('Error: $e');
    }

    setState(() {
      _isAuthenticated = isAuthenticated;
    });

    if (isAuthenticated) {
      // Proceed with logged-in state or navigate to the home screen
    }
  }

  void updateBiometricPreference(bool isEnabled) async {
    await BiometricPreferenceManager().setBiometricPreference(isEnabled);
  }

  void toggleTheme(bool value) {
    setState(() {
      _darkModeEnabled = value;
    });
    // You can add logic here to update the app theme based on the value of `_darkModeEnabled`
    // For example, you can use a package like `provider` to manage the app theme state globally and update it accordingly.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(
              Icons.fingerprint,
              size: 35.0,
            ),
            title: Text('Enable Biometrics'),
            subtitle: Text('Login with biometric authentication'),
            trailing: Switch(
              value: _enableBiometrics,
              onChanged: (value) {
                setState(() {
                  _enableBiometrics = value;
                });
                updateBiometricPreference(
                    value); // Update the biometric preference when the switch is toggled
              },
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.lightbulb,
              size: 35.0,
            ),
            title: Text('Dark Mode'),
            subtitle: Text('Toggle dark mode'),
            trailing: Switch(
              value: _darkModeEnabled,
              onChanged:
                  toggleTheme, // Call the `toggleTheme` method when the switch is toggled
            ),
          ),
        ],
      ),
    );
  }
}
