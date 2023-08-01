import 'package:companion/screens/CareGiverScanner.dart';
import 'package:companion/screens/GenerateQRCode.dart';
import 'package:companion/screens/forgot_password.dart';
import 'package:companion/screens/hompage.dart';
import 'package:companion/utils/registration.dart';
import 'package:companion/utils/signup_with_google.dart';
import 'package:flutter/material.dart';
import 'package:companion/utils/auth_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();

  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  final GoogleAuthService googleSignUp = GoogleAuthService();
  final LocalAuthentication auth = LocalAuthentication();
  bool _isPasswordVisible = false;
  String _selectedRole = 'patient';

  void gSignUp() async {
    // Create an instance of GoogleAuthService
    final GoogleAuthService authService = GoogleAuthService();

    // Call the signInWithGoogle method
    authService.signInWithGoogle().then((userCredential) {
      // Handle the user credential
      if (userCredential != null) {
        // User signed in successfully
        Text('Successfully Signed Up with Google');
      } else {
        // Sign-in with Google was cancelled or failed
        Text('Failed to Signed Up with Google');
      }
    });
  }

  Future<void> login() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter email and password'),
        ),
      );
      return;
    }

    bool loginSuccessful = await _authService.login(email, password);

    if (loginSuccessful) {
      // Store login status and token
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool('isLoggedIn', true);
      prefs.setString('token', 'YOUR_TOKEN_HERE');

      // Check the selected role and navigate accordingly
      if (_selectedRole == 'patient') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else if (_selectedRole == 'caregiver') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CareGiverScanner()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid email or password'),
        ),
      );
    }
  }

  void checkBiometricAuthentication() async {
    bool isLoggedIn = await _authService.isLoggedIn();

    if (isLoggedIn) {
      // User is already logged in, navigate to the home page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      List<BiometricType> availableBiometrics =
          await auth.getAvailableBiometrics();

      if (canCheckBiometrics && availableBiometrics.isNotEmpty) {
        // Try to authenticate with biometrics
        bool authenticated = await auth.authenticate(
          localizedReason: 'Scan your fingerprint (or face) to authenticate',
        );

        if (authenticated) {
          // If successful, navigate to the home page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        }
      }
    }
  }

  // @override
  // void initState() {
  //   super.initState();
  //   checkBiometricAuthentication();
  //   WidgetsBinding.instance!.addPostFrameCallback((_) async {
  //     SharedPreferences prefs = await SharedPreferences.getInstance();
  //     bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  //     String token = prefs.getString('token') ?? '';

  //     if (isLoggedIn && token.isNotEmpty) {
  //       checkBiometricAuthentication();
  //     }
  //   });
  // }

  @override
void initState() {
  super.initState();
  WidgetsBinding.instance!.addPostFrameCallback((_) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    String token = prefs.getString('token') ?? '';

    if (isLoggedIn && token.isNotEmpty) {
      // User is already logged in, but we don't want to automatically redirect
      // to the homepage. You can remove the code related to biometric authentication
      // or modify it as per your requirements.
      // Remove the code below if you don't want any automatic redirection.
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (context) => HomePage()),
      // );
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      body: Stack(
        children: [
          Container(
            padding: EdgeInsets.only(top: 125),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
            ),
          ),
          SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundImage: AssetImage('assets/login.jpg'),
                    backgroundColor: Colors.blueAccent[600],
                  ),
                  SizedBox(
                    height: 40,
                  ),
                  Center(
                    child: Text(
                      'Welcome to your\n\t\t\tCompanion...',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 30,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 35, right: 35),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatefulBuilder(
                          builder:
                              (BuildContext context, StateSetter setState) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Transform.scale(
                                  scale: 1.0,
                                  child: Radio(
                                    value: 'patient',
                                    groupValue: _selectedRole,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedRole = value as String;
                                      });
                                    },
                                  ),
                                ),
                                Text(
                                  'Patient',
                                  style: TextStyle(fontSize: 15),
                                ),
                                SizedBox(
                                  width: 30,
                                ),
                                Transform.scale(
                                  scale: 1.0,
                                  child: Radio(
                                    value: 'caregiver',
                                    groupValue: _selectedRole,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedRole = value as String;
                                      });
                                    },
                                  ),
                                ),
                                Text(
                                  'Caregiver',
                                  style: TextStyle(fontSize: 15),
                                ),
                              ],
                            );
                          },
                        ),
                        TextField(
                          controller: _emailController,
                          style: TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            fillColor: Colors.indigo[50],
                            filled: true,
                            hintText: "Email",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        TextField(
                          controller: _passwordController,
                          style: TextStyle(),
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            fillColor: Colors.indigo[50],
                            filled: true,
                            hintText: "Password",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Forgot Password',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  color: Color(0xff4c505b),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Center(
                          child: ElevatedButton(
                            onPressed: login,
                            child: Text('Login'),
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: gSignUp,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/google_logo.png',
                                    height: 24.0,
                                  ),
                                  SizedBox(width: 8.0),
                                  Text('Sign Up with Google'),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RegistrationPage(),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(width: 8.0),
                                  Text('Registration'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
