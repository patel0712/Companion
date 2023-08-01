import 'package:companion/utils/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:email_validator/email_validator.dart';

import 'dart:math';

enum UserRole { Patient, Caregiver }

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController relationController = TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  final IconData visibilityOffIcon = Icons.visibility_off;
  final IconData visibilityIcon = Icons.visibility;

  UserRole selectedUserRole = UserRole.Patient;

  Future<void> registerUser(String email, String password) async {
    String confirmPassword = confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      print('Password and Confirm Password do not match.');
      return;
    }

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('User registered: ${userCredential.user!.uid}');
      // Redirect to the login page after successful registration
      Navigator.pushReplacementNamed(context,
          '/login'); // Replace '/login' with your actual login page route
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        Fluttertoast.showToast(
          msg: 'The password provided is too weak. Change Your Password',
          toastLength: Toast.LENGTH_SHORT,
        );
      } else if (e.code == 'email-already-in-use') {
        Fluttertoast.showToast(
          msg: 'The account already exists for that email.',
          toastLength: Toast.LENGTH_SHORT,
        );
      }
    } catch (e) {
      print(e);
    }
  }

  // Future<void> addUserDetails(String name, String phone, String email,
  //     String password, String relation, UserRole userType) async {
  //   CollectionReference users = FirebaseFirestore.instance.collection('users');
  //   CollectionReference caregivers = FirebaseFirestore.instance.collection('caregivers');

  //     String caregiverId = await generateCaregiverId(); // Generate a caregiver ID
  //     String patientId = await generatePatientId();

  //   // Create a new instance of UserData
  //   try {

  //     if (selectedUserRole == UserRole.Patient) {
  //       UserData userData = UserData(
  //         patientId: patientId,
  //         name: name,
  //         phone: phone,
  //         email: email,
  //         password: password,
  //         userType: userType,
  //       );
  //       Map<String, dynamic> userDataMap = userData.toMap();
  //       await users.doc(email).set(userDataMap);
  //     } else if (selectedUserRole == UserRole.Caregiver) {
  //       CaregiverData caregiverData = CaregiverData(
  //         caregiverId: caregiverId,
  //         name: name,
  //         phone: phone,
  //         email: email,
  //         password: password,
  //         relation: relation,
  //         userType: userType,
  //       );
  //       Map<String, dynamic> caregiverDataMap = caregiverData.toMap();
  //       await caregivers.doc(caregiverId).set(
  //           caregiverDataMap); // Store the data with caregiverId as the document ID
  //     }

  //     // Convert UserData instance to a Map using the toMap() method

  //     print('User details added to Firestore');

  //     // Send the patient ID to the registered email
  //     sendPatientIdToEmail(patientId, email);
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  void addPatientDetails(String name, String phone, String email,
      String password, UserRole userType) async {
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    String patientId = await generatePatientId();

    UserData userData = UserData(
      patientId: patientId,
      name: name,
      phone: phone,
      email: email,
      password: password,
      // userType: userType,
    );
    Map<String, dynamic> userDataMap = userData.toMap();
    await users.doc(email).set(userDataMap);

    print('Patient details added to Firestore');

    sendPatientIdToEmail(patientId, email);
  }

  void addCaregiverDetails(String name, String phone, String email,
      String password, String relation, UserRole userType) async {
    CollectionReference caregivers =
        FirebaseFirestore.instance.collection('caregivers');
    String caregiverId = await generateCaregiverId();

    CaregiverData caregiverData = CaregiverData(
      caregiverId: caregiverId,
      name: name,
      phone: phone,
      email: email,
      password: password,
      relation: relation,
      // userType: userType,
    );
    Map<String, dynamic> caregiverDataMap = caregiverData.toMap();
    await caregivers.doc(caregiverId).set(caregiverDataMap);

    print('Caregiver details added to Firestore');
  }

  Future<String> generateCaregiverId() async {
    Random random = Random();
    int caregiverId;
    do {
      caregiverId = random.nextInt(9000000) + 1000000;
    } while (await caregiverIdExists(caregiverId));
    return caregiverId.toString();
  }

  Future<String> generatePatientId() async {
    Random random = Random();
    int patientId;
    do {
      patientId = random.nextInt(9000000) + 1000000;
    } while (await patientIdExists(patientId));
    return patientId.toString();
  }

  Future<bool> caregiverIdExists(int caregiverId) async {
    CollectionReference caregivers =
        FirebaseFirestore.instance.collection('caregivers');
    QuerySnapshot querySnapshot = await caregivers
        .where('caregiverId', isEqualTo: caregiverId.toString())
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  Future<bool> patientIdExists(int patientId) async {
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    QuerySnapshot querySnapshot =
        await users.where('patientId', isEqualTo: patientId.toString()).get();
    return querySnapshot.docs.isNotEmpty;
  }

  void sendPatientIdToEmail(String patientId, String mail) async {
    final Email email = Email(
      subject: 'Patient ID',
      body:
          'Welcome to Your Companion here your generated Patient-ID : $patientId',
      recipients: [mail],
      cc: ['support.companion@gmail.com'],
      isHTML: false,
    );

    await FlutterEmailSender.send(email);

    // For demonstration purposes, we'll print the patient ID and email to the console
    print('Patient ID: $patientId');
    print('Email: $email');
  }

  void submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Get user input values from text fields
    String name = nameController.text.trim();
    String phone = phoneController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String relation = relationController.text.trim();

    // Call registerUser function to create new user account
    registerUser(email, password).then((value) {
      // Call addUserDetails function to add user details to Firestore
      if (selectedUserRole == UserRole.Patient) {
        addPatientDetails(name, phone, email, password, selectedUserRole);
      } else if (selectedUserRole == UserRole.Caregiver) {
        addCaregiverDetails(
            name, phone, email, password, relation, selectedUserRole);
      }

      // Show a toast message or navigate to the login page
      Fluttertoast.showToast(
        msg: 'Registration successful. Patient ID sent to your email.',
        toastLength: Toast.LENGTH_SHORT,
      );

      // Navigate to the login page
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Registration'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select User Role:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Radio(
                      value: UserRole.Patient,
                      groupValue: selectedUserRole,
                      onChanged: (UserRole? value) {
                        setState(() {
                          selectedUserRole = value!;
                        });
                      },
                    ),
                    Text('Patient'),
                    SizedBox(
                      width: 30,
                    ),
                    Radio(
                      value: UserRole.Caregiver,
                      groupValue: selectedUserRole,
                      onChanged: (UserRole? value) {
                        setState(() {
                          selectedUserRole = value!;
                        });
                      },
                    ),
                    Text('Caregiver'),
                  ],
                ),
                SizedBox(height: 16.0),
                Text(
                  selectedUserRole == UserRole.Patient
                      ? 'Patient Registration:'
                      : 'Care Giver Registration:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!EmailValidator.validate(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible ? visibilityIcon : visibilityOffIcon,
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !isPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        isConfirmPasswordVisible
                            ? visibilityIcon
                            : visibilityOffIcon,
                      ),
                      onPressed: () {
                        setState(() {
                          isConfirmPasswordVisible = !isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !isConfirmPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != passwordController.text.trim()) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                if (selectedUserRole == UserRole.Caregiver) ...[
                  TextFormField(
                    controller: relationController,
                    decoration: InputDecoration(
                      labelText: 'Relation with Patient',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your relation with the patient';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.0),
                ],
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // Call the submitForm function here
                      submitForm();
                    },
                    child: Text('Register'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CaregiverData {
  final String caregiverId;
  final String name;
  final String phone;
  final String email;
  final String password;
  final String relation;
  // final UserRole userType;

  CaregiverData({
    required this.caregiverId,
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
    required this.relation,
    // required this.userType,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
      'relation': relation,
      // 'userType': userType == UserRole.Patient ? 'patient' : 'caregiver',
    };
  }
}

class UserData {
  final String patientId;
  final String name;
  final String phone;
  final String email;
  final String password;
  // final UserRole userType;

  UserData({
    required this.patientId,
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
    // required this.userType,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
      // 'userType': userType == UserRole.Patient ? 'patient' : 'caregiver',
    };
  }
}
