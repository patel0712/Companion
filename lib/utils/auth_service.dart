import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  SharedPreferences? _prefs;
  final String _isLoggedInKey = 'isLoggedIn';

  User? get currentUser => _auth.currentUser;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<bool> isLoggedIn() async {
    await init();
    return _prefs?.getBool(_isLoggedInKey) ?? false;
  }

  // Login with email and password
  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await setLoggedInStatus(true);
      return true; // Login successful
    } catch (e) {
      print(e);
      return false; // Login failed
    }
  }

  Future<void> setLoggedInStatus(bool isLoggedIn) async {
    await init();
    await _prefs?.setBool(_isLoggedInKey, isLoggedIn);
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      print('Login Error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await setLoggedInStatus(false);
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      print('Registration Error: $e');
      return null;
    }
  }

    User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<UserData?> getUserDataByEmail(String email) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.size > 0) {
        // User with the provided email exists in the database
        var userData = querySnapshot.docs.first.data();
        return UserData.fromMap(userData as Map<String, dynamic>);
      } else {
        // User with the provided email doesn't exist in the database
        return null;
      }
    } catch (e) {
      print('Error retrieving user data: $e');
      return null;
    }
  }
}

class UserData {
  final String? patientId;
  final String? name;
  final String? phone;
  final String? email;
  final String? password;
  final String? avatarUrl;
  UserData({
    this.patientId,
    this.name,
    this.phone,
    this.email,
    this.password,
    this.avatarUrl,
  });

  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      patientId: map['patientId'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      password: map['password'],
      avatarUrl: map['avatar_url'],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'patientId': patientId,
      'phone': phone,
      'email': email,
      'password': password,
      'avatar_url': avatarUrl,
    };
  }
}
