import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:companion/utils/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class UserService {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late User? currentUser = getCurrentUser();

  Future<Map<String, dynamic>?> fetchCurrentUserData() async {
    if (currentUser != null) {
      String email = currentUser!.email!;
      UserData? userData = await _authService.getUserDataByEmail(email);
      if (userData != null) {
        // Data retrieved successfully
        // Access the fields of the userData object as needed
        String? name = userData.name;
        String? patientId = userData.patientId;
        String? phone = userData.phone;

        // Retrieve the image URL from Firebase Realtime Database
        final String userId = currentUser!.uid;
        final DatabaseReference databaseReference =
            FirebaseDatabase.instance.ref().child('users').child(userId);
        DatabaseEvent event = await databaseReference.once();
        final DataSnapshot? dataSnapshot = event.snapshot;
        final Map<dynamic, dynamic> values =
            dataSnapshot?.value as Map<dynamic, dynamic>;

        // Get the avatar URL from the DataSnapshot
        final Object? imageUrl = dataSnapshot?.child('avatar_url').value;
        print('imageUrl: $imageUrl');

        // Create a map with the retrieved user data
        Map<String, dynamic> patientDataMap = {
          'name': name,
          'patientId': patientId,
          'phone': phone,
          'avatar_url': imageUrl,
          'email': email,
        };

        return patientDataMap;
      } else {
        // User data not found in the database
        // Handle the case when the user data is missing
        print('User data not found in the database');
        return null;
      }
    } else {
      // No current user
      // Handle the case when there is no signed-in user
      print('No current user');
      return null;
    }
  }

  Future<String?> getPatientId() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot snapshot =
            await _firestore.collection('users').doc(user.email).get();

        if (snapshot.exists) {
          var userData = snapshot.data() as Map<String, dynamic>;
          String? patientId = userData['patientId'];
          return patientId;
        } else {
          print('User data not found');
          return null;
        }
      } catch (e) {
        print('Error retrieving user data: $e');
        return null;
      }
    } else {
      print('User not logged in');
      return null;
    }
  }

  String? getCurrentUserEmail() {
    User? user = _auth.currentUser;
    return user?.email;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<void> updatePatientDataByEmail(
      String email, Map<String, dynamic> updatedData) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.size > 0) {
        // User with the provided email exists in the database
        var documentId = querySnapshot.docs.first.id;

        // Update the user data using the document ID
        await _firestore
            .collection('users')
            .doc(documentId)
            .update(updatedData);
      } else {
        // User with the provided email doesn't exist in the database
        print('User not found');
      }
    } catch (e) {
      print('Error updating user data: $e');
    }
  }

  Future<void> updateCaregiverStatus(String caregiverId, bool isScanned) async {
    try {
      await _firestore
          .collection('caregivers')
          .doc(caregiverId)
          .update({'isScanned': isScanned});
    } catch (e) {
      print('Error updating caregiver status: $e');
    }
  }

  Future<Map<String, dynamic>?> getCaregiverData(String caregiverId) async {
    try {
      DocumentSnapshot snapshot =
          await _firestore.collection('caregivers').doc(caregiverId).get();

      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      } else {
        print('Caregiver data not found');
        return null;
      }
    } catch (e) {
      print('Error retrieving caregiver data: $e');
      return null;
    }
  }

  Future<String?> getCareGiverId() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot snapshot =
            await _firestore.collection('caregivers').doc(user.email).get();

        if (snapshot.exists) {
          var caregiverData = snapshot.data() as Map<String, dynamic>;
          String? caregiverId = caregiverData['caregiverId'];
          return caregiverId;
        } else {
          print('Caregiver data not found');
          return null;
        }
      } catch (e) {
        print('Error retrieving caregiver data: $e');
        return null;
      }
    } else {
      print('User not logged in');
      return null;
    }
  }

  String? getCareGiverEmail() {
    User? user = _auth.currentUser;
    return user?.email;
  }

  Future<void> updateCaregiverDataByEmail(
      String email, Map<String, dynamic> updatedData) async {
    // Existing code...
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('caregivers')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.size > 0) {
        // User with the provided email exists in the database
        var documentId = querySnapshot.docs.first.id;

        // Update the user data using the document ID
        await _firestore
            .collection('caregivers')
            .doc(documentId)
            .update(updatedData);
      } else {
        // User with the provided email doesn't exist in the database
        print('User not found');
      }
    } catch (e) {
      print('Error updating user data: $e');
    }
  }

  Future<void> saveScannedCaregiverDetails(
      String caregiverId, bool isScanned) async {
    try {
      await _firestore
          .collection('caregivers')
          .doc(caregiverId)
          .update({'isScanned': isScanned});
    } catch (e) {
      print('Error saving scanned caregiver details: $e');
    }

    Future<void> acknowledgeQRScan(
        String name, String email, String caregiverId) async {
      try {
        final url =
            'https://your-api-endpoint.com/acknowledge-scan'; // Update with your API endpoint

        // Get the current user's ID token
        final User? user = _auth.currentUser;
        if (user == null) {
          print('User not authenticated');
          return;
        }
        final idToken = await user.getIdToken();

        // Fetch caregiver data from Firestore
        final caregiverData = await getCaregiverData(caregiverId);
        if (caregiverData == null) {
          print('Caregiver data not found');
          return;
        }
        final bool isScanned = caregiverData['isScanned'] ?? false;

        // Construct the request body
        final body = {
          'name': name,
          'email': email,
          'caregiverId': caregiverId,
          'isScanned': isScanned,
          'idToken': idToken,
        };

        // Make the HTTP POST request
        final response = await http.post(
          Uri.parse(url),
          body: jsonEncode(body),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          // Successful acknowledgment
          print('QR scan acknowledged: $name, $email, $caregiverId');
        } else {
          // Failed acknowledgment
          print('Failed to acknowledge QR scan: ${response.statusCode}');
        }
      } catch (e) {
        // Error occurred during acknowledgment
        print('Error acknowledging QR scan: $e');
      }
    }
  }
}

class BiometricPreferenceManager {
  static const String _biometricPrefKey = 'biometricPrefKey';

  Future<bool> getBiometricPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricPrefKey) ?? false;
  }

  Future<void> setBiometricPreference(bool isEnabled) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(_biometricPrefKey, isEnabled);
  }
}
