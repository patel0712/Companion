import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'dart:convert';
import 'dart:async';

class ActivityReminder extends StatefulWidget {
  const ActivityReminder({Key? key}) : super(key: key);

  @override
  State<ActivityReminder> createState() => ActivityReminderState();
}

class ActivityReminderState extends State<ActivityReminder> {
  List<Activity> activities = [];
  Set<int> selectedIndices = {};

  Timer? _expirationTimer;
  bool deleteMode = false;

  @override
  void initState() {
    super.initState();
    _loadActivities();
    _startExpirationTimer();
  }

  @override
  void dispose() {
    _expirationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedActivities = prefs.getStringList('activities');
    if (savedActivities != null) {
      setState(() {
        activities = savedActivities
            .map((activityJson) => Activity.fromJson(json.decode(activityJson)))
            .toList();
      });
    }
  }

  Future<void> _saveActivities() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> updatedActivitiesJson = activities
        .map((activity) => json.encode(activity.toJson()))
        .toList()
        .cast<String>();
    await prefs.setStringList('activities', updatedActivitiesJson);
  }

  void _startExpirationTimer() {
    _expirationTimer = Timer.periodic(Duration(hours: 12), (_) {
      setState(() {
        activities.removeWhere((activity) => activity.isExpired());
        selectedIndices.clear();
      });
      _saveActivities();
    });
  }

  void _toggleDeleteMode() {
    setState(() {
      deleteMode = !deleteMode;
      if (!deleteMode) {
        selectedIndices.clear();
      }
    });
  }

  void _deleteSelectedActivities() {
    setState(() {
      activities.removeWhere(
          (activity) => selectedIndices.contains(activities.indexOf(activity)));
      selectedIndices.clear();
    });
    _saveActivities();
    _toggleDeleteMode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activity Reminder'),
        actions: [
          if (deleteMode)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deleteSelectedActivities,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          bool? result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddActivity()),
          );
          if (result != null && result) {
            _loadActivities();
          }
        },
        tooltip: 'Activity Reminder',
        child: Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: activities.length,
        itemBuilder: (context, index) {
          return Dismissible(
            key: ValueKey(activities[index]),
            background: Container(color: Colors.red),
            onDismissed: (direction) {
              setState(() {
                activities.removeAt(index);
              });
              _saveActivities();
            },
            child: GestureDetector(
              onLongPress: () {
                setState(() {
                  if (!deleteMode) {
                    deleteMode = true;
                    selectedIndices.add(index);
                  }
                });
              },
              onTap: () {
                if (deleteMode) {
                  setState(() {
                    if (selectedIndices.contains(index)) {
                      selectedIndices.remove(index);
                    } else {
                      selectedIndices.add(index);
                    }
                  });
                }
              },
              child: Card(
                child: ListTile(
                  title: Text(activities[index].activity),
                  subtitle: Text(activities[index].time),
                  trailing: deleteMode
                      ? Icon(selectedIndices.contains(index)
                          ? Icons.check_circle
                          : Icons.circle_outlined)
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AddActivity extends StatefulWidget {
  @override
  State<AddActivity> createState() => _AddActivityState();
}

class _AddActivityState extends State<AddActivity> {
  TextEditingController _activityController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _scheduleNotification(
      String activity, TimeOfDay selectedTime) async {
    DateTime now = DateTime.now();
    DateTime scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'your_channel_id',
        title: 'Activity Reminder',
        body: activity,
      ),
      schedule: NotificationCalendar.fromDate(date: scheduledDateTime),
    );
  }

  void _addActivity() async {
    String activity = _activityController.text.trim();
    if (activity.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? activitiesJson = prefs.getStringList('activities');
      List<Activity> activities = [];
      if (activitiesJson != null) {
        activities = activitiesJson
            .map((activityJson) => Activity.fromJson(json.decode(activityJson)))
            .toList();
      }
      Activity newActivity = Activity(
        activity: activity,
        time: _selectedTime.format(context),
      );
      activities.add(newActivity);
      List<String> updatedActivitiesJson = activities
          .map((activity) => json.encode(activity.toJson()))
          .toList()
          .cast<String>();
      await prefs.setStringList('activities', updatedActivitiesJson);

      newActivity = Activity(
        activity: activity,
        time: _selectedTime.format(context),
      );
      activities.add(newActivity);

      await _scheduleNotification(newActivity.activity, _selectedTime);

      Navigator.pop(context, true); // Navigate back to ActivityReminder screen with a result
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Activity'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _activityController,
            decoration: InputDecoration(labelText: 'Activity'),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Text('Time: '),
              InkWell(
                onTap: () => _selectTime(context),
                child: Text(
                  _selectedTime.format(context),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: _addActivity,
          child: Text('Add'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
      ],
    );
  }
}

class Activity {
  final String activity;
  final String time;

  Activity({required this.activity, required this.time});

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      activity: json['activity'] as String,
      time: json['time'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activity': activity,
      'time': time,
    };
  }

  bool isExpired() {
    DateTime currentTime = DateTime.now();
    DateTime activityTime = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
      _parseHour(),
      _parseMinute(),
    );
    DateTime expirationTime = activityTime.add(Duration(hours: 12));
    return currentTime.isAfter(expirationTime);
  }

  int _parseHour() {
    List<String> timeParts = time.split(':');
    return int.parse(timeParts[0]);
  }

  int _parseMinute() {
    List<String> timeParts = time.split(':');
    return int.parse(timeParts[1]);
  }
}
