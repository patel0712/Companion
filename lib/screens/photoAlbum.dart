// ignore_for_file: unnecessary_cast

import 'dart:async';
import 'dart:io';
import 'package:companion/utils/auth_service.dart';
import 'package:companion/utils/user_service.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';

class PhotoAlbum extends StatefulWidget {
  const PhotoAlbum({Key? key}) : super(key: key);

  @override
  State<PhotoAlbum> createState() => PhotoAlbumState();
}

class PhotoAlbumState extends State<PhotoAlbum> {
  UserService userService = UserService();
  String? userEmail;

  bool _isLoadingImages = true;
  File? _image;
  final picker = ImagePicker();
  late DatabaseReference _databaseReference;
  DatabaseReference databaseReference =
      FirebaseDatabase.instance.ref().child('photo_album');

  late List<AlbumEntry> _albumEntries;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _relationController = TextEditingController();

  Future getImageFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future getImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<void> uploadImage() async {
    if (_image == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('No Image Selected'),
            content: Text('Please select an image to upload.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    String imageName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference firebaseStorageRef =
        FirebaseStorage.instance.ref().child('images/$imageName.jpg');

    UploadTask uploadTask = firebaseStorageRef.putFile(_image!);
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});

    if (taskSnapshot.state == TaskState.success) {
      String imageUrl = await firebaseStorageRef.getDownloadURL();
      saveImageToDatabase(imageUrl);
    }
  }

  void saveImageToDatabase(String imageUrl) {
    String name = _nameController.text;
    String relation = _relationController.text;
    DatabaseReference databaseReference =
        FirebaseDatabase.instance.ref().child('photo_album');

    DatabaseReference newEntryReference = databaseReference.push();
    // String patientId = newEntryReference.key!;
    // Future<String?> patientId = authService.getPatientId();

    newEntryReference.set({
      'email': userEmail,
      'name': name,
      'relation': relation,
      'image_url': imageUrl,
    }).then((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Image Uploaded'),
            content: Text('The image has been uploaded successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      _nameController.clear();
      setState(() {
        _image = null;
      });
    }).catchError((error) {
      print('Failed to upload image: $error');
    });
  }

  void _deleteImage(AlbumEntry albumEntry) {
    DatabaseReference databaseReference =
        FirebaseDatabase.instance.ref().child('photo_album');

    databaseReference
        .orderByChild('image_url')
        .equalTo(albumEntry.imageUrl)
        .once()
        .then((DatabaseEvent event) {
          DataSnapshot snapshot = event.snapshot;
          if (snapshot.value != null) {
            Map<dynamic, dynamic>? data =
                snapshot.value as Map<dynamic, dynamic>?;

            String? entryKey = data?.keys.first as String?;
            if (entryKey != null) {
              databaseReference.child(entryKey).remove().then((_) {
                setState(() {
                  _albumEntries.remove(albumEntry);
                });
              }).catchError((error) {
                print('Failed to delete image: $error');
              });
            }
          }
        } as FutureOr Function(DatabaseEvent value))
        .catchError((error) {
      print('Failed to fetch image: $error');
    });
  }

  Future<List<AlbumEntry>> fetchAlbumEntries() async {
    List<AlbumEntry> entries = [];
    _databaseReference = FirebaseDatabase.instance.ref().child('photo_album');
    _albumEntries = [];

    // Listen for child events using onChildAdded
    _databaseReference.onChildAdded.listen((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      final albumEntry = AlbumEntry.fromSnapshot(snapshot);
      setState(() {
        _albumEntries.add(albumEntry);
      });
      // Check if all images have been loaded
      if (_albumEntries.length == _albumEntries.length) {
        setState(() {
          _isLoadingImages = false; // All images loaded
        });
      }
    });

    // Fetch initial album entries using once
    DatabaseEvent event = await _databaseReference.once();
    Map<dynamic, dynamic>? data =
        event.snapshot.value as Map<dynamic, dynamic>?;

    if (data != null) {
      data.forEach((key, value) {
        if (value['email'] == userEmail) {
          AlbumEntry entry = AlbumEntry.fromSnapshot(value);
          entries.add(entry);
        }
      });
    }
    return entries;
  }

  void _showFullScreenDialog(AlbumEntry albumEntry) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(albumEntry.imageUrl),
              ListTile(
                title: Text('Name: ' + albumEntry.name),
                subtitle: Text('Relation: ' + albumEntry.relation),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    userEmail = userService.getCurrentUserEmail();
    _databaseReference = FirebaseDatabase.instance.ref().child('photo_album');
    _albumEntries = [];

    fetchAlbumEntries().then((entries) {
      setState(() {
        _albumEntries = entries;
        _isLoadingImages = false;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 159, 179, 213),
      appBar: AppBar(
        title: Text('Album Book'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Add Image'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                      ),
                    ),
                    SizedBox(height: 16.0),
                    TextField(
                      controller: _relationController,
                      decoration: InputDecoration(
                        labelText: 'Relation',
                      ),
                    ),
                    SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: getImageFromCamera,
                          child: Text('Camera'),
                        ),
                        ElevatedButton(
                          onPressed: getImageFromGallery,
                          child: Text('Gallery'),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      uploadImage();
                    },
                    child: Text('Upload'),
                  ),
                ],
              );
            },
          );
        },
        tooltip: 'Add Address',
        child: const Icon(Icons.add),
      ),
      body: GridView.builder(
        shrinkWrap: true,
        // Replace this widget with the code above
        itemCount: _albumEntries.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (BuildContext context, int index) {
          final albumEntry = _albumEntries[index];

          return GestureDetector(
            onTap: () {
              _showFullScreenDialog(albumEntry);
            },
            child: AlbumEntry(
              name: albumEntry.name,
              relation: albumEntry.relation,
              imageUrl: albumEntry.imageUrl,
              onDelete: () => _deleteImage(albumEntry),
            ),
          );
        },
      ),
    );
  }
}

class AlbumEntry extends StatefulWidget {
  final String name;
  final String relation;
  final String imageUrl;
  final String? email;
  final VoidCallback? onDelete;
  const AlbumEntry({
    Key? key,
    required this.name,
    required this.relation,
    required this.imageUrl,
    this.onDelete,
    this.email,
  }) : super(key: key);

  factory AlbumEntry.fromSnapshot(DataSnapshot snapshot) {
    final Map<dynamic, dynamic>? data =
        snapshot.value as Map<dynamic, dynamic>?;
    return AlbumEntry(
      email: data?['email'] as String? ?? '',
      name: data?['name'] as String? ?? '',
      relation: data?['relation'] as String? ?? '',
      imageUrl: data?['image_url'] as String? ?? '',
    );
  }

  @override
  _AlbumEntryState createState() => _AlbumEntryState();
}

class _AlbumEntryState extends State<AlbumEntry> {
  final _longPressRecognizer = LongPressGestureRecognizer();

  @override
  void initState() {
    super.initState();
    _longPressRecognizer.onLongPress = _handleLongPress;
  }

  @override
  void dispose() {
    _longPressRecognizer.dispose();
    super.dispose();
  }

  void _handleLongPress() {
    // Delayed delete action
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Image'),
          content: Text('Are you sure you want to delete this image?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDelete!();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadImage(widget.imageUrl),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return GestureDetector(
            onLongPress: _handleLongPress,
            child: SizedBox(
              width: 200,
              height: 300,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Color.fromARGB(255, 174, 211, 241),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                10), // Set the border radius
                            border:
                                Border.all(color: Colors.black87, width: 2.0),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: 300,
                                height: 400,
                                child: Image.memory(snapshot.data as Uint8List),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Name: ' + widget.name,
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      Text(
                        'Relation: ' + widget.relation,
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Text('Error loading image: ${snapshot.error}');
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }

  Future<Uint8List> _loadImage(String imageUrl) async {
    // You can use any method to load the image data from the URL
    // Here we use the http package for simplicity
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load image');
    }
  }
}
