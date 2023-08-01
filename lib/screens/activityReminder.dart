import 'package:flutter/material.dart';
import 'adding_screens/addActivity.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ActivityReminder extends StatefulWidget {
  const ActivityReminder({Key? key}) : super(key: key);

  @override
  State<ActivityReminder> createState() => ActivityReminderState();
}

class ActivityReminderState extends State<ActivityReminder> {
  List<Activity> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  void _loadActivities() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedActivities = prefs.getStringList('activities');
    List<Activity> activities = [];
    if (savedActivities != null) {
      activities = savedActivities
          .map((activityJson) => Activity.fromJson(jsonDecode(activityJson)))
          .toList();
    }
    setState(() {
      _activities = activities;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activity Reminder'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddActivity()),
          ).then((value) {
            _loadActivities(); // Refresh the activities after adding a new one
          });
        },
        tooltip: 'Activity Reminder',
        child: Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: _activities.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              title: Text(_activities[index].activity),
              subtitle: Text(_activities[index].time),
            ),
          );
        },
      ),
    );
  }
}

class Activity {
  late String activity;
  late String time;

  Activity({required this.activity, required this.time});

  Activity.fromJson(Map<String, dynamic> json) {
    activity = json['activity'] as String;
    time = json['time'] as String;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['activity'] = this.activity;
    data['time'] = this.time;
    return data;
  }
}
