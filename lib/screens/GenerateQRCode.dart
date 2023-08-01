import 'dart:convert';

import 'package:companion/utils/user_service.dart';
import 'package:flutter/material.dart';
import 'CareGiverScanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

UserService userService = UserService();

class GenerateQRCode extends StatefulWidget {
  // const GenerateQRCode({Key key});

  @override
  GenerateQRCodeState createState() => GenerateQRCodeState();
}

class GenerateQRCodeState extends State<GenerateQRCode> {
  TextEditingController controller = TextEditingController();

  String? scannedCaregiverId;
  String? scannedUserName;
  String? scannedUserEmail;
  bool qrScanned = false;

  Future<void> fetchCaregiverData(String caregiverId) async {
    // Fetch the caregiver data from the database based on the caregiverId
    // You can use the UserService or any other method to retrieve the caregiver data
    Map<String, dynamic>? caregiverData =
        await userService.getCaregiverData(caregiverId);

    if (caregiverData != null) {
      // Update the caregiver details on the patient's device
      setState(() {
        scannedUserName = caregiverData['name'];
        scannedUserEmail = caregiverData['email'];
      });
    }
  }

void onUserScanned(String name, String email, String caregiverId) {
  if (caregiverId.isNotEmpty && caregiverId.length == 10) {
    setState(() {
      scannedUserName = name;
      scannedUserEmail = email;
      scannedCaregiverId = caregiverId;
      qrScanned = true; // Update the qrScanned flag
    });
    fetchCaregiverData(caregiverId);
    userService.updateCaregiverStatus(caregiverId, true);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invalid QR code'),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  @override
  void initState() {
    super.initState();
    generateQRCode();
  }

  Future<void> generateQRCode() async {
    final patientId = await userService.getPatientId();
    setState(() {
      controller.text = patientId ?? '';
    });
  }

  Future<Map<String, dynamic>?> getUserData() async {
    Map<String, dynamic>? userData = await userService.fetchCurrentUserData();
    return userData;
  }

  @override
  void dispose() {
    // Dispose the controller when the widget is disposed
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Care Giver Login QR'),
      centerTitle: true,
    ),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        qrImage(),
        Container(
          margin: const EdgeInsets.all(20),
          child: Text('Patient ID: ' + controller.text),
        ),
        SizedBox(
          height: 30.0,
        ),
        if (qrScanned)
          Column(
            children: [
              Text('Scanned User Details:'),
              Text('Name: $scannedUserName'),
              Text('Email: $scannedUserEmail'),
              Text('Caregiver ID: $scannedCaregiverId'),
            ],
          ),
      ],
    ),
  );
}

  Widget qrImage() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: getUserData(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final userData = snapshot.data!;
          final imageUrl = userData['avatar_url'];
          final patientId = userData['patientId'];
          final patientName = userData['name'];

          final encodedData = {
            'patientId': patientId,
            'name': patientName,
            'avatar_url': imageUrl
          };
          final encodedDataString = jsonEncode(encodedData);

          return Center(
            child: QrImageView(
              gapless: false,
              data: encodedDataString,
              size: 200,
            ),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}
