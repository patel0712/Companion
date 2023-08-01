import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:companion/screens/pillSchedule.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddMedicine extends StatefulWidget {
  final Medicine? medicine;

  const AddMedicine({Key? key, this.medicine}) : super(key: key);

  @override
  _AddMedicineState createState() => _AddMedicineState();
}

class _AddMedicineState extends State<AddMedicine> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  DateTime? selectedTime;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.medicine != null) {
      nameController.text = widget.medicine!.name;
      dosageController.text = widget.medicine!.dosage;
      selectedTime = widget.medicine!.time;
    }
  }

  void saveMedicine() async {
    if (_formKey.currentState!.validate()) {
      if (nameController.text.isNotEmpty &&
          dosageController.text.isNotEmpty &&
          selectedTime != null) {
        Medicine newMedicine = Medicine(
          name: nameController.text,
          dosage: dosageController.text,
          time: selectedTime!,
        );

        // Save medicine data to local storage
        SharedPreferences prefs = await SharedPreferences.getInstance();
        List<String> medicineData = [
          newMedicine.name,
          newMedicine.dosage,
          DateFormat('hh:mm:ss a').format(newMedicine.time),
        ];
        List<String> existingMedicineData =
            prefs.getStringList('medicineData') ?? [];
        existingMedicineData.add(medicineData.join(','));
        prefs.setStringList('medicineData', existingMedicineData);

        // Schedule the alarm notification
        setAlarm(newMedicine.time);

        // Pop the screen and pass the newMedicine object back
        Navigator.pop(context, newMedicine);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a time'),
          ),
        );
      }
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedTime = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> setAlarm(DateTime time) async {
    int id = DateTime.now().millisecondsSinceEpoch;
    String title = 'Medicine Alarm';

    // Create the notification content.
    NotificationContent content = NotificationContent(
      id: id,
      channelKey: 'medicine',
      title: title,
      body: 'Time to take medicine!',
    );

    DateTime currentTime = DateTime.now();

    // Compare the selected time with the current system time
    if (time.toUtc().isAfter(currentTime)) {
      // Selected time is in the future, schedule the notification
      AwesomeNotifications().createNotification(
        content: content,
        schedule: NotificationCalendar(
          year: time.year,
          month: time.month,
          day: time.day,
          hour: time.hour,
          minute: time.minute,
          second: time.second,
        ),
      );
    } else {
      // Selected time is in the past, notify immediately
      AwesomeNotifications().createNotification(
        content: content,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Medicine'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Medicine Name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a medicine name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: dosageController,
                decoration: InputDecoration(
                  labelText: 'Dosage',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a dosage';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  _selectTime(context);
                },
                child: Center(child: Text('Select Time')),
              ),
              SizedBox(height: 16.0),
              Text(
                'Selected Time: ${selectedTime != null ? DateFormat('hh:mm:ss a').format(selectedTime!) : 'Not selected'}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  saveMedicine();
                },
                child: Center(child: Text('Save')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
