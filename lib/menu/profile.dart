import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:companion/utils/user_service.dart';
import 'package:companion/utils/auth_service.dart';

class ProfileEditPage extends StatefulWidget {
  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  // Declare variables for user data
  String? name;
  String? email;
  String? phone;
  String? imageUrl;
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  // Create instances of the required services
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  // Declare a variable for enabled state
  bool enabled = false;
  bool isEditable = false;

  late User? currentUser = _authService.getCurrentUser() as User?;
  File? _image;
  NetworkImage? _networkImage;
  UserService userService = UserService();

  Future<void> _showImagePickerOptions(enabled) async {
    final ImagePicker picker = ImagePicker();

    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 150,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    child: Icon(
                      Icons.photo_library,
                      size: 80,
                      color: Colors.blue,
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        _uploadImageAndSaveURL(image);
                      }
                    },
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Gallery',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    child: Icon(
                      Icons.camera_alt,
                      size: 80,
                      color: Colors.blue,
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.camera,
                      );
                      if (image != null) {
                        _uploadImageAndSaveURL(image);
                      }
                    },
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Camera',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadImageAndSaveURL(XFile image) async {
    setState(() {
      _image = File(image.path);
    });

    // Upload the image to Firebase Storage
    final String userId = currentUser!.uid;
    final String fileName = '${userId}_avatar.jpg';
    final Reference storageReference =
        FirebaseStorage.instance.ref().child('user_avatars').child(fileName);
    final UploadTask uploadTask = storageReference.putFile(_image!);
    final TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});

    if (taskSnapshot.state == TaskState.success) {
      final String imageUrl = await storageReference.getDownloadURL();

      // Save the image URL to Firebase Realtime Database
      final DatabaseReference databaseReference =
          FirebaseDatabase.instance.ref().child('users').child(userId);
      await databaseReference.update({'avatar_url': imageUrl});
    }
  }

  @override
  void initState() {
    super.initState();
    // Call the method to fetch user data when the page is initialized
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    // Get the current user's email
    String? userEmail = _userService.getCurrentUserEmail();

    // Fetch the user data using the email
    Map<String, dynamic>? userData = await _userService.fetchCurrentUserData();

    if (userData != null) {
      // Update the state with the retrieved user data
      setState(() {
        nameController.text = userData['name'] ?? '';
        emailController.text = userData['email'] ?? '';
        phoneController.text = userData['phone'] ?? '';
        imageUrl = userData['avatar_url'] ?? '';
      });
    }
  }

  Future<void> _updateUserData() async {
    // Get the current user's email
    String? userEmail = _userService.getCurrentUserEmail();

    // Create a map with the updated user data
    Map<String, dynamic> updatedData = {
      'name': nameController.text,
      'email': emailController.text,
      'phone': phoneController.text,
    };

    // Update the user data in the database using the email
    await _userService.updatePatientDataByEmail(userEmail!, updatedData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile updated')),
    );
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed.
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  if (enabled) {
                    _showImagePickerOptions(enabled);
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<Map<String, dynamic>?>(
                      future: userService.fetchCurrentUserData(),
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
                          final imageUrl = snapshot.data?['avatar_url'];
                          final uniqueUrl = imageUrl != null
                              ? '$imageUrl?timestamp=${DateTime.now().millisecondsSinceEpoch}'
                              : null;

                          return CircleAvatar(
                            radius: 80,
                            backgroundImage: uniqueUrl != null
                                ? NetworkImage(uniqueUrl) as ImageProvider
                                : AssetImage('assets/person.png'),
                            backgroundColor: Color.fromARGB(255, 57, 177, 251),
                          );
                        } else {
                          // Data not available
                          // Display default CircleAvatar with AssetImage
                          return CircleAvatar(
                            radius: 80,
                            backgroundImage: AssetImage('assets/person.png'),
                            backgroundColor: Color.fromARGB(255, 57, 177, 251),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 20,
              ),
              // Add form fields for editing/updating the user data
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                ),
                enabled: enabled,
                onChanged: (value) {
                  setState(() {
                    name = value;
                  });
                },
              ),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                ),
                enabled: enabled,
                onChanged: (value) {
                  setState(() {
                    email = value;
                  });
                },
              ),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                ),
                enabled: enabled,
                onChanged: (value) {
                  setState(() {
                    phone = value;
                  });
                },
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Change the value of the variable to true
                      setState(() {
                        enabled = true;
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          // Check if the button is enabled or not
                          if (enabled) {
                            // Return the disabled color
                            return Colors.grey;
                          }
                          // Return the enabled color
                          return Colors.blue;
                        },
                      ),
                    ),
                    child: Text('Edit'),
                  ),
                  SizedBox(
                    width: 30,
                  ),
                  // Add a button to update the user data
                  ElevatedButton(
                    onPressed: () {
                      // Call a method to update the user data in the database
                      _updateUserData();
                      Navigator.pushNamed(context, '/home');
                    },
                    child: Text('Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
