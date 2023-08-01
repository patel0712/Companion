import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:companion/screens/adding_screens/addMedicine.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PillSchedule extends StatefulWidget {
  const PillSchedule({Key? key}) : super(key: key);

  @override
  State<PillSchedule> createState() => PillScheduleState();
}

class PillScheduleState extends State<PillSchedule> {
  List<Medicine> medicines = [];
  int? selectedCardIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMedicineData();
  }

  void _loadMedicineData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> medicineData = prefs.getStringList('medicineData') ?? [];
    List<Medicine> loadedMedicines = [];

    for (String data in medicineData) {
      List<String> fields = data.split(',');
      if (fields.length == 3) {
        String name = fields[0];
        String dosage = fields[1];
        DateTime time = DateFormat('hh:mm:ss a').parse(fields[2]);
        loadedMedicines.add(Medicine(name: name, dosage: dosage, time: time));
      }
    }

    setState(() {
      medicines = loadedMedicines;
    });
  }

  void _editMedicine(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicine(
          medicine: medicines[index],
        ),
      ),
    );

    if (result != null && result is Medicine) {
      setState(() {
        medicines[index] = result;
      });
    }
  }

  // void _deleteMedicine(int index) {
  //   setState(() {
  //     Navigator.of(context).pop(); // Close the dialog
  //     medicines.removeAt(index);
  //   });
  // }

  void _saveMedicineData(List<Medicine> medicines) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> medicineData = [];

    for (Medicine medicine in medicines) {
      String data =
          '${medicine.name},${medicine.dosage},${DateFormat('hh:mm:ss a').format(medicine.time)}';
      medicineData.add(data);
    }

    prefs.setStringList('medicineData', medicineData);
  }

  void showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this medicine?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                deleteMedicineCard(index);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void deleteMedicineCard(int index) async {
    setState(() {
      Navigator.of(context).pop();
      medicines.removeAt(index);
    });

    // Update local storage
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> medicineData = medicines.map((med) {
      return '${med.name},${med.dosage},${DateFormat('hh:mm:ss a').format(med.time)}';
    }).toList();

    await prefs.setStringList('medicineData', medicineData);

    // Close the popup if the selected card is deleted
    if (selectedCardIndex == index) {
      setState(() {
        selectedCardIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 159, 179, 213),
      appBar: AppBar(
        title: Text('Medicine Reminder'),
      ),
      body: ListView.builder(
        itemCount: medicines.length,
        itemBuilder: (context, index) {
          return MedicineCard(
            medicine: medicines[index],
            onEdit: () {
              _editMedicine(index);
            },
            onDelete: () {
              showDeleteConfirmationDialog(index);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddMedicine()),
          );

          if (result != null && result is Medicine) {
            setState(() {
              medicines.add(result);
            });

            // Create a notification.
            AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: medicines.length,
                channelKey: 'medicine',
                title: result.name,
              ),
            );
          }
        },
        tooltip: 'Add Medicine',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;
  MedicineCard({
    Key? key,
    required this.medicine,
    this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat('hh:mm:ss a').format(medicine.time);
    return Card(
      color: Color.fromARGB(255, 205, 219, 241),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Expanded(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: SizedBox(
                  width: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medicine: ${medicine.name}',
                        style: TextStyle(fontSize: 20),
                      ),
                      Text(
                        'Dosage: ${medicine.dosage}',
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        'Time: ${formattedTime}',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: onEdit,
                    child: Icon(Icons.edit_rounded),
                  ),
                  SizedBox(
                    height: 14,
                  ),
                  InkWell(
                    onTap: onDelete,
                    child: Icon(Icons.delete_rounded),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
class Medicine {
  String name;
  String dosage;
  DateTime time;

  Medicine({required this.name, required this.dosage, required this.time});
}
