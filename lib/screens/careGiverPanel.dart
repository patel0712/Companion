import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:companion/utils/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../menu/menu.dart';

class CareGiverPanel extends StatefulWidget {
  @override
  State<CareGiverPanel> createState() => _CareGiverPanelState();
}

class _CareGiverPanelState extends State<CareGiverPanel> {
  AuthService authService = AuthService();
  late User? currentUser = authService.getCurrentUser() as User?;
  File? _image;
  String? givenPatientID;
  NetworkImage? _networkImage;
  UserService userService = UserService();

  DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();

  Future<String?> sharedPatientId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    givenPatientID = prefs.getString('patientId');
    return givenPatientID;
  }

  Future<Map<String, dynamic>?> fetchUserData(String patientId) async {
    // Fetch the patient data from the database based on the given patient ID
    DatabaseEvent event = await _databaseReference
        .child('users')
        .orderByChild('patientId')
        .equalTo(givenPatientID)
        .once();

    // Extract the data from the snapshot
    Map<dynamic, dynamic>? data =
        event.snapshot.value as Map?; // Use snapshot property here
    if (data != null) {
      // Assuming each patientId is unique, there should be only one entry in the snapshot
      Map<String, dynamic> patientData = data.values.first;
      String? fetchedPatientId = patientData['patientId'];

      if (fetchedPatientId == patientId) {
        // Patient data retrieved successfully and patient IDs match
        // Access the fields of the patientData map as needed
        String? name = patientData['name'];
        String? phone = patientData['phone'];
        String? imageUrl = patientData['avatar_url'];

        // Return the patient data
        return patientData;
      } else {
        // Patient IDs do not match
        print('Given patient ID does not match the retrieved patient ID');
        return null;
      }
    } else {
      // User data not found in the database or no patient with the given ID
      print('User data not found or no patient with the given ID');
      return null;
    }
  }

  Widget functionality({
    required String image,
    required String name,
    required String routeName,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, routeName);
        },
        child: Container(
          padding: EdgeInsets.only(top: 10.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Image.asset(image),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                name,
                style: const TextStyle(fontSize: 17),
              ),
            ],
          ),
        ),
      ),
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isPanelOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color.fromARGB(255, 21, 146, 248),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: Color.fromARGB(255, 21, 146, 248),
        leading: IconButton(
          icon: Icon(Icons.menu_rounded),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: const Text(
          "Caregiver Panel",
          style: TextStyle(
            fontSize: 23,
          ),
        ),
      ),
      drawer: Drawer(
        child: MenuDrawer(),
      ),
      body: GestureDetector(
        onTap: () {
          if (_isPanelOpen) {
            _scaffoldKey.currentState?.openEndDrawer();
          }
        },
        child: Container(
          height: 800,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.indigo[50],
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(0),
              topRight: Radius.circular(0),
            ),
          ),
          child: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.only(
                  top: 30,
                  left: 30,
                ),
                child: Text(
                  "Patient Details",
                  style: TextStyle(
                    fontSize: 19,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 120,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.0),
                            color: Color.fromARGB(255, 143, 199, 244),
                          ),
                          margin: const EdgeInsets.all(5.0),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      FutureBuilder<Map<String, dynamic>?>(
                                        future: sharedPatientId().then(
                                            (patientId) =>
                                                fetchUserData(patientId!)),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            // Data retrieval is still in progress
                                            // Display a loading indicator
                                            return CircularProgressIndicator();
                                          } else if (snapshot.hasError) {
                                            // Handle the error case
                                            return Text('Something went wrong');
                                          } else if (snapshot.hasData) {
                                            final imageUrl =
                                                snapshot.data?['avatar_url'];
                                            final uniqueUrl = imageUrl != null
                                                ? '$imageUrl?timestamp=${DateTime.now().millisecondsSinceEpoch}'
                                                : null;

                                            return CircleAvatar(
                                              radius: 40,
                                              backgroundImage: uniqueUrl != null
                                                  ? NetworkImage(uniqueUrl)
                                                      as ImageProvider
                                                  : AssetImage(
                                                      'assets/person.png'),
                                              backgroundColor: Color.fromARGB(
                                                  255, 57, 177, 251),
                                            );
                                          } else {
                                            // Data not available
                                            // Display default CircleAvatar with AssetImage
                                            return CircleAvatar(
                                              radius: 40,
                                              backgroundImage: AssetImage(
                                                  'assets/person.png'),
                                              backgroundColor: Color.fromARGB(
                                                  255, 57, 177, 251),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: FutureBuilder<Map<String, dynamic>?>(
                                    future: sharedPatientId().then(
                                        (patientId) =>
                                            fetchUserData(patientId!)),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        String? name = snapshot.data?['name'];
                                        String? patientId =
                                            snapshot.data?['patientId'];
                                        String? phone = snapshot.data?['phone'];

                                        // Display the data in a column
                                        return Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Patient ID : $patientId',
                                              style: TextStyle(
                                                fontSize: 18.0,
                                              ),
                                            ),
                                            Text(
                                              'Name : $name',
                                              style: TextStyle(
                                                fontSize: 18.0,
                                              ),
                                            ),
                                            Text(
                                              "Mobile no. : $phone",
                                              style: TextStyle(
                                                fontSize: 18.0,
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 30.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Say By..Bye... to Dementia 😉',
                      style: TextStyle(
                        fontSize: 20.0,
                        // fontFamily: ,
                        color: Colors.black,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        top: 20,
                      ),
                      child: SizedBox(
                        height: 500.0,
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.30,
                          children: [
                            Container(
                              child: functionality(
                                image: 'assets/address_book.png',
                                name: 'Address Book',
                                routeName: "/address",
                              ),
                            ),
                            Container(
                              child: functionality(
                                image: "assets/photo_album.png",
                                name: 'Photo Album Book',
                                routeName: "/album",
                              ),
                            ),
                            Container(
                              child: functionality(
                                image: "assets/pill_reminder.png",
                                name: 'Pill Schedule',
                                routeName: "/pill",
                              ),
                            ),
                            Container(
                              child: functionality(
                                image: "assets/yoga.png",
                                name: 'Exercises',
                                routeName: "/exercise",
                              ),
                            ),
                            Container(
                              child: functionality(
                                image: "assets/activity_reminder.png",
                                name: 'Activity Reminder',
                                routeName: "/activity",
                              ),
                            ),
                            Container(
                              child: functionality(
                                image: "assets/location.png",
                                name: 'Current Location',
                                routeName: "/curr_location",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
