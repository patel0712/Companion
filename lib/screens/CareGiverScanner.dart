// ignore_for_file: dead_code

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'GenerateQRCode.dart';
import 'package:companion/screens/careGiverPanel.dart';
import 'package:companion/screens/hompage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class CareGiverScanner extends StatefulWidget {
  final void Function(String name, String email, String caregiverId)?
      onUserScanned;
  CareGiverScanner({Key? key, this.onUserScanned}) : super(key: key);

  @override
  State<CareGiverScanner> createState() => _CareGiverScannerState();
}

class _CareGiverScannerState extends State<CareGiverScanner> {
  var generateQRCode = GenerateQRCodeState();
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  String scannedUserName = '';
  String scannedUserEmail = '';
  String scannedCaregiverId = '';
  bool scanned = false; // Flag to track if a successful scan has occurred
  QRViewController? controller;
  Barcode? result;
  bool scanning = true;

  // void acknowledgeQRScan(String name, String email, String caregiverId) async {
  //   try {
  //     final url =
  //         'https://console.firebase.google.com/project/your-companion-41ca1/usage/details'; // Update with your API endpoint
  //     final response = await http.post(
  //       Uri.parse(url),
  //       body: {
  //         'name': name,
  //         'email': email,
  //         'caregiverId': caregiverId,
  //       },
  //     );

  //     if (response.statusCode == 200) {
  //       // Successful acknowledgment
  //       print('QR scan acknowledged: $name, $email, $caregiverId');
  //     } else {
  //       // Failed acknowledgment
  //       print('Failed to acknowledge QR scan: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     // Error occurred during acknowledgment
  //     print('Error acknowledging QR scan: $e');
  //   }
  // }

  // void onUserScanned(String name, String email, String caregiverId) async {
  //   if (caregiverId.isNotEmpty && caregiverId.length == 10) {
  //     setState(() {
  //       scannedUserName = name;
  //       scannedUserEmail = email;
  //       scannedCaregiverId = caregiverId;
  //       scanned = true;
  //     });

  //     try {
  //       final url =
  //           'https://console.firebase.google.com/project/your-companion-41ca1/usage/details'; // Replace with your Firebase Cloud Function URL
  //       final response = await http.post(
  //         Uri.parse(url),
  //         body: {
  //           'name': name,
  //           'email': email,
  //           'caregiverId': caregiverId,
  //         },
  //       );

  //       if (response.statusCode == 200) {
  //         // Successful acknowledgment
  //         showDialog(
  //           context: context,
  //           barrierDismissible: false,
  //           builder: (BuildContext context) {
  //             return AlertDialog(
  //               title: Text('Confirm Caregiver'),
  //               content: SizedBox(
  //                 height: 132,
  //                 child: Column(
  //                   children: [
  //                     // Display confirmation details to the patient (implement your own UI here)
  //                   ],
  //                 ),
  //               ),
  //               actions: [
  //                 TextButton(
  //                   child: Text('Cancel'),
  //                   onPressed: () {
  //                     Navigator.of(context).pop();
  //                   },
  //                 ),
  //                 TextButton(
  //                   child: Text('Confirm'),
  //                   onPressed: () {
  //                     Navigator.push(
  //                       context,
  //                       MaterialPageRoute(
  //                           builder: (context) => CareGiverPanel()),
  //                     );
  //                     // Send confirmation response back to the caregiver's device
  //                     // confirmCaregiver(caregiverId);
  //                     Navigator.of(context).pop();
  //                   },
  //                 ),
  //               ],
  //             );
  //           },
  //         );
  //       } else {
  //         // Error handling for confirmation request failure
  //         showDialog(
  //           context: context,
  //           builder: (BuildContext context) {
  //             return AlertDialog(
  //               title: Text('Confirmation Request Failed'),
  //               content: Text('Failed to send confirmation request.'),
  //               actions: [
  //                 TextButton(
  //                   child: Text('OK'),
  //                   onPressed: () {
  //                     Navigator.of(context).pop();
  //                   },
  //                 ),
  //               ],
  //             );
  //           },
  //         );
  //       }
  //     } catch (e) {
  //       // Error handling for network request failure
  //       showDialog(
  //         context: context,
  //         builder: (BuildContext context) {
  //           return AlertDialog(
  //             title: Text('Error'),
  //             content: Text(
  //                 'An error occurred while sending the confirmation request.'),
  //             actions: [
  //               TextButton(
  //                 child: Text('OK'),
  //                 onPressed: () {
  //                   Navigator.of(context).pop();
  //                 },
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //     }
  //   }
  // }

// Method to send confirmation response to the caregiver's device
  // Future<void> confirmCaregiver(String caregiverId) async {
  //   try {
  //     // Send a network request to the patient's server to check confirmation status
  //     final url =
  //         'http://patient-device-ip:3000/check-confirmation'; // Replace 'patient-device-ip' with the actual IP address of the patient's device
  //     final response = await http.get(Uri.parse(url));

  //     if (response.statusCode == 200) {
  //       final confirmed = json.decode(response.body)['confirmed'];
  //       if (confirmed) {
  //         // Caregiver confirmed
  //         // Proceed to caregiver panel or perform additional actions
  //       } else {
  //         // Caregiver not confirmed
  //       }
  //     } else {
  //       // Error handling for confirmation status check failure
  //     }
  //   } catch (e) {
  //     // Error handling for network request failure
  //   }
  // }

  void onUserScanned(String name, String email, String caregiverId) async {
    if (caregiverId.isNotEmpty && caregiverId.length == 10) {
      setState(() {
        scannedUserName = name;
        scannedUserEmail = email;
        scannedCaregiverId = caregiverId;
        scanned = true;
      });

      // Store the scan data to local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', name);
      await prefs.setString('email', email);
      await prefs.setString('caregiverId', caregiverId);

      // Pass the caregiverId to the onUserScanned callback
      widget.onUserScanned?.call(name, email, caregiverId);
    }
  }

  void qr(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((event) {
      setState(() {
        result = event;
        // Extract user details from the scanned QR code
        final userDetails = result!.code!.split(',');
        if (userDetails.length >= 3) {
          final name = userDetails[0];
          final email = userDetails[1];
          final caregiverId = userDetails[2];
          // Invoke the onUserScanned callback with the user details
          onUserScanned(name, email, caregiverId);
        }
      });
    });
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      if (!scanned) {
        final decodedData = json.decode(scanData.code!);
        final name = decodedData['name'];
        final avatar_url = decodedData['avatar_url'];
        final patientId = decodedData['patientId'];
        controller.pauseCamera(); // pause the camera after scanning
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Confirm Patient'),
              content: SizedBox(
                height: 132,
                child: Column(
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(avatar_url),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            text: 'Patient Id: ',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: '$patientId',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            text: 'Name: ',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: '$name',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: Text('Confirm'),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CareGiverPanel()),
                    );
                  },
                ),
              ],
            );
            setState(() {
              scanned = true;
            });
          },
        );
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.red,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
