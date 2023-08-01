import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';

class AddAddress extends StatefulWidget {
  const AddAddress({
    Key? key,
    this.initialName,
    this.initialPhone,
    this.initialAddress,
  }) : super(key: key);

  final String? initialName;
  final String? initialPhone;
  final String? initialAddress;

  @override
  State<AddAddress> createState() => AddAddressState();
}

class AddAddressState extends State<AddAddress> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _addressController = TextEditingController();

  File? _image;
  late String? currentUserUID;


  final _formKey = GlobalKey<FormState>(); // create a global key for the form

  DatabaseReference _databaseReference =
      FirebaseDatabase.instance.ref().child('addressbook');
  @override
  void initState() {
    super.initState();
    currentUserUID = FirebaseAuth.instance.currentUser?.uid;
    _databaseReference = FirebaseDatabase.instance.ref().child('addressbook');
    if (widget.initialName != null) {
      _nameController.text = widget.initialName!;
    }
    if (widget.initialPhone != null) {
      _phoneController.text = widget.initialPhone!;
    }
    if (widget.initialAddress != null) {
      _addressController.text = widget.initialAddress!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> saveAddress() async {
    // remove the parameters
    String name = _nameController.text; // assign from text controllers
    String phone = _phoneController.text;
    String address = _addressController.text;

    // Get the current user's email ID
    User? user = FirebaseAuth.instance.currentUser;
    String? email = user?.email;
    DatabaseReference newAddressRef = _databaseReference.push();
    try {
      // add a try-catch block
      await newAddressRef.set({
        // use await to wait for the future

        'email': email,
        'name': name,
        'phone': phone,
        'address': address,
      });
      Navigator.of(context).pop({
        'name': name,
        'phone': phone,
        'address': address,
      });
    } catch (e) {
      // handle any errors here
      print(e);
    }
  }

  Future<void> _showImagePickerOptions() async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(
    source: ImageSource.gallery, // You can change this to ImageSource.camera to capture from the camera
  );

  if (image != null) {
    setState(() {
      _image = File(image.path);
    });

    // Upload the image to Firebase Storage
    final String? userId = currentUserUID;
    final String fileName = '${userId}_avatar.jpg';
    final Reference storageReference =
        FirebaseStorage.instance.ref().child('user_avatars').child(fileName);
    final UploadTask uploadTask = storageReference.putFile(_image!);
    final TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});

    if (taskSnapshot.state == TaskState.success) {
      final String imageUrl = await storageReference.getDownloadURL();

      // Save the image URL to Firebase Realtime Database
      final DatabaseReference databaseReference =
          FirebaseDatabase.instance.ref().child('users').child(currentUserUID!);
      await databaseReference.update({'avatar_url': imageUrl});
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[100],
      appBar: AppBar(
        title: const Text('Add Address'),
        centerTitle: true,
      ),
      body: Form(
        // wrap the column in a form widget
        key: _formKey, // assign the global key
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _showImagePickerOptions,
              child: CircleAvatar(
                radius: 70,
                backgroundImage: AssetImage('assets/person.png'),
                backgroundColor: Colors.blue[300],
              ),
            ),
            SizedBox(height: 10),
            CustomTextField(
              controller: _nameController,
              labelText: 'Name',
              validator: (value) {
                // add a validator function
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            CustomTextField(
              controller: _phoneController,
              labelText: 'Phone',
              validator: (value) {
                // add a validator function
                if (value == null || value.isEmpty) {
                  return 'Please enter a phone number';
                }
                return null;
              },
            ),
            CustomTextField(
              controller: _addressController,
              labelText: 'Address',
              validator: (value) {
                // add a validator function
                if (value == null || value.isEmpty) {
                  return 'Please enter an address';
                }
                return null;
              },
            ),
            ElevatedButton(
              onPressed: saveAddress, // remove the parentheses
              child: const Text('Save Details'),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    required this.validator, // add a validator parameter
  }) : super(key: key);

  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)
      validator; // specify the type of the validator

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TextFormField(
        // use TextFormField instead of TextField
        controller: controller,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          labelText: labelText,
        ),
        validator: validator, // assign the validator property
      ),
    );
  }
}
