// ignore_for_file: prefer_const_constructors, dead_code
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:companion/screens/adding_screens/addAddress.dart';

class AddressBook extends StatefulWidget {
  const AddressBook({Key? key}) : super(key: key);

  @override
  State<AddressBook> createState() => AddressBookState();
}

class AddressCard extends StatefulWidget {
  const AddressCard({
    Key? key,
    required this.addressKey,
    required this.name,
    required this.phone,
    required this.address,
    required this.onDelete,
    required this.onEdit,
    this.avatarUrl,
  }) : super(key: key);

  final String addressKey;
  final String name;
  final String phone;
  final String address;
  final VoidCallback onDelete;
  final String? avatarUrl;
  final Function(String name, String phone, String address) onEdit;

  @override
  _AddressCardState createState() => _AddressCardState();
}

class _AddressCardState extends State<AddressCard> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  late String updatedName;
  late String updatedPhone;
  late String updatedAddress;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    phoneController = TextEditingController(text: widget.phone);
    addressController = TextEditingController(text: widget.address);
    updatedName = widget.name;
    updatedPhone = widget.phone;
    updatedAddress = widget.address;
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  void toggleEdit() {
    if (isEditing) {
      // Save changes
      setState(() {
        widget.onEdit(updatedName, updatedPhone, updatedAddress);
        isEditing = false;
      });
    } else {
      // Enter editing mode
      setState(() {
        isEditing = true;
      });
    }
  }

  void confirmDelete() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Address'),
          content: Text('Are you sure you want to delete this address?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                widget
                    .onDelete(); // Call the onDelete callback to remove the address
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundImage: AssetImage('assets/person.png'),
              backgroundColor: Color.fromARGB(255, 122, 159, 231),
            ),
            SizedBox(
              width: 20,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isEditing)
                    TextField(
                      controller: nameController,
                      onChanged: (value) {
                        setState(() {
                          updatedName = value;
                        });
                      },
                      decoration: InputDecoration(labelText: 'Name'),
                    )
                  else
                    Text(
                      'Name: ${widget.name}',
                      style: TextStyle(
                        fontSize: 18,
                        // fontWeight: FontWeight.bold,
                      ),
                    ),
                  SizedBox(height: 8),
                  if (isEditing)
                    TextField(
                      controller: phoneController,
                      onChanged: (value) {
                        setState(() {
                          updatedPhone = value;
                        });
                      },
                      decoration: InputDecoration(labelText: 'Phone'),
                    )
                  else
                    Text(
                      'Phone: ${widget.phone}',
                      style: TextStyle(fontSize: 16),
                    ),
                  SizedBox(height: 8),
                  if (isEditing)
                    TextField(
                      controller: addressController,
                      onChanged: (value) {
                        setState(() {
                          updatedAddress = value;
                        });
                      },
                      decoration: InputDecoration(labelText: 'Address'),
                    )
                  else
                    Text(
                      'Address: ${widget.address}',
                      style: TextStyle(fontSize: 16),
                    ),
                  SizedBox(
                    width: 8,
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(isEditing ? Icons.save : Icons.edit_rounded),
                    onPressed: toggleEdit,
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed:
                        confirmDelete, // Show confirmation dialog before deleting
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddressBookState extends State<AddressBook> {
  int selectedCardIndex = -1;
  late String? currentUserEmail;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    currentUserEmail = FirebaseAuth.instance.currentUser?.email;
  }

  void deleteAddress(String addressKey) {
    DatabaseReference addressRef =
        FirebaseDatabase.instance.ref().child('addressbook').child(addressKey);

    addressRef.remove().then((_) {
      // Address successfully deleted
    }).catchError((error) {
      // Handle any errors that occur during the delete operation
      print('Error deleting address: $error');
    });
  }

  void onPressed(int index) {
    setState(() {
      if (selectedCardIndex == index) {
        selectedCardIndex = -1; // Deselect the card if tapped again
      } else {
        selectedCardIndex = index; // Select the tapped card
      }
    });
  }

  DatabaseReference _databaseReference =
      FirebaseDatabase.instance.ref().child('addressbook');

  Future<List<Map<String, dynamic>>> getAddressList() async {
    DatabaseEvent event = await _databaseReference.once();
    DataSnapshot dataSnapshot = event.snapshot;
    List<Map<String, dynamic>> addressList = [];

    if (dataSnapshot.value != null) {
      List<dynamic> values = dataSnapshot.value as List<dynamic>;
      values.forEach((value) {
        Map<String, dynamic> address = {
          'name': value['name'],
          'phone': value['phone'],
          'address': value['address'],
        };
        addressList.add(address);
      });
    }

    return addressList;
  }

  Map<String, dynamic> _addresses = {};

  Future<void> _loadAddresses() async {
    Map<String, dynamic> addresses =
        (await getAddressList()) as Map<String, dynamic>;
    if (addresses != null) {
      setState(() {
        _addresses = addresses;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Address Book'),
        centerTitle: true,
        actions: [
          if (selectedCardIndex !=
              -1) // Show delete icon only when a card is selected
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  // savedAddresses.removeAt(selectedCardIndex);
                  selectedCardIndex = -1; // Reset the selected card index
                });
              },
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          return StreamBuilder(
            stream: _databaseReference.onValue,
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasData &&
                  !snapshot.hasError &&
                  snapshot.data?.snapshot?.value != null) {
                User? user = FirebaseAuth.instance.currentUser;
                String? email = user?.email;
                Map<dynamic, dynamic> data =
                    snapshot.data?.snapshot?.value as Map<dynamic, dynamic>;
                Map<String, dynamic> addressList = {};
                data.forEach((key, value) {
                  Map<String, dynamic> address =
                      Map<String, dynamic>.from(value as Map<dynamic, dynamic>);
                  if (address['email'] == currentUserEmail) {
                    addressList[key] = address;
                  }
                });
                return ListView.builder(
                  itemCount: addressList.length,
                  itemBuilder: (context, index) {
                    String addressKey = addressList.keys.elementAt(index);
                    Map<String, dynamic> address = addressList[addressKey];
                    return AddressCard(
                      addressKey: addressKey,
                      name: address['name']!,
                      phone: address['phone']!,
                      address: address['address']!,
                      onDelete: () {
                        setState(() {
                          deleteAddress(addressKey);
                          addressList.remove(addressKey);
                        });
                      },
                      onEdit: (String name, String phone, String address) {
                        DatabaseReference addressRef = FirebaseDatabase.instance
                            .ref()
                            .child('addressbook')
                            .child(addressKey);

                        addressRef.update({
                          'name': name,
                          'phone': phone,
                          'address': address,
                        }).then((_) {
                          // Database update successful
                          // You can handle any further actions here, such as showing a success message
                        }).catchError((error) {
                          // Handle any errors that occur during the update
                          print('Error updating address: $error');
                        });
                      },
                    );
                  },
                );
              } else {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final Map<String, String> result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddAddress(),
            ),
          );
        },
        tooltip: 'Add Address',
        child: const Icon(Icons.add),
      ),
    );
  }
}
