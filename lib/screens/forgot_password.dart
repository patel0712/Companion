// forgot_password.dart
import 'package:companion/utils/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  TextEditingController emailController = TextEditingController();

  void resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      Fluttertoast.showToast(
        msg: 'Password reset email sent. Please check your inbox.',
        toastLength: Toast.LENGTH_LONG,
      );
    } catch (e) {
      print('Error sending password reset email: $e');
      Fluttertoast.showToast(
        msg: 'Failed to send password reset email. Please try again.',
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  void submitForm() {
    String email = emailController.text.trim();
    resetPassword(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot Password'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 16.0),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
              ),
            ),
            SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: submitForm,
              child: Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }
}
