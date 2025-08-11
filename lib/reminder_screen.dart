import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'notification_service.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final NotificationService notificationService = NotificationService();
  final AudioPlayer audioPlayer = AudioPlayer();

  String? selectedDay;
  TimeOfDay? selectedTime;
  String? selectedActivity;

  final List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final List<String> activities = [
    'Wake up',
    'Go to gym',
    'Breakfast',
    'Meetings',
    'Lunch',
    'Quick nap',
    'Go to library',
    'Dinner',
    'Go to sleep',
  ];

  @override
  void initState() {
    super.initState();
    notificationService.initialize();
  }

  Future<void> _playSound() async {
    await audioPlayer.play(AssetSource('assets/sounds/reminder.mp3'));
  }

  Future<void> _scheduleNotification() async {
    if (selectedDay == null || selectedTime == null || selectedActivity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all fields')),
      );
      return;
    }

    final now = DateTime.now();
    final currentDay = now.weekday;
    final selectedDayIndex = daysOfWeek.indexOf(selectedDay!) + 1;
    
    int daysToAdd = (selectedDayIndex - currentDay) % 7;
    if (daysToAdd < 0) daysToAdd += 7;
    
    DateTime scheduledDate = DateTime(
      now.year,
      now.month,
      now.day + daysToAdd,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    if (daysToAdd == 0 && scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    await notificationService.scheduleNotification(
      id: selectedDayIndex,
      title: 'Reminder: $selectedActivity',
      body: 'Time to $selectedActivity!',
      scheduledDate: scheduledDate,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder set for $selectedDay at ${selectedTime!.format(context)}')),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Reminder'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedDay,
                    hint: const Text('Select day'),
                    items: daysOfWeek.map((String day) {
                      return DropdownMenuItem<String>(
                        value: day,
                        child: Text(day),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedDay = newValue;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Select time',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        selectedTime != null
                            ? selectedTime!.format(context)
                            : 'Select time',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedActivity,
                    hint: const Text('Select activity'),
                    items: activities.map((String activity) {
                      return DropdownMenuItem<String>(
                        value: activity,
                        child: Text(activity),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedActivity = newValue;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _scheduleNotification,
              child: const Text('Set Reminder'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Daily Activities:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...activities.map((activity) => ListTile(
                  title: Text(activity),
                  leading: const Icon(Icons.check_circle_outline),
                )),
          ],
        ),
      ),
    );
  }
}