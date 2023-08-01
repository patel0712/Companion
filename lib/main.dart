// ignore_for_file: prefer_const_constructors

import 'package:companion/screens/activityReminder.dart';
import 'package:companion/screens/careGiverPanel.dart';
import 'package:companion/screens/currentLocation.dart';
import 'package:companion/screens/excercise.dart';
import 'package:companion/screens/hompage.dart';
import 'package:companion/screens/loginpage.dart';
import 'package:companion/screens/photoAlbum.dart';
import 'package:companion/screens/pillSchedule.dart';
import 'package:flutter/material.dart';
import 'screens/addressbook.dart';
import 'package:firebase_core/firebase_core.dart';
import 'utils/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/login',
        routes: {
          '/login': (context) => LoginPage(),
          '/home': (context) => HomePage(),
          '/address': (context) => AddressBook(),
          '/album': (context) => PhotoAlbum(),
          '/pill': (context) => PillSchedule(),
          '/excercise': (context) => Excercise(),
          '/activity': (context) => ActivityReminder(),
          '/curr_location': (context) => MapScreen(),
          '/caregiver': (context) => CareGiverPanel(),

        },
      ),
    );
  } catch (e) {
    print('Error: $e');
  }
}
