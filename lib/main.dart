import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(Lab4());
}

class Lab4 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Заверување термини за испити',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Login'),
              onPressed: () async {
                String email = _emailController.text.trim();
                String password = _passwordController.text.trim();
                try {
                  UserCredential userCredential =
                  await _auth.signInWithEmailAndPassword(
                      email: email, password: password);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                } catch (e) {
                  print('Најавувањето е неуспешно: $e');
                  // Handle login error
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Заверување термини за испити'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddExamScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2024, 12, 31),
            focusedDay: DateTime.now(),
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              _selectedDay = selectedDay;
            },
          ),
          Expanded(
            child: StreamBuilder(
              stream: _firestore.collection('exams').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                var exams = snapshot.data.docs;
                return ListView.builder(
                  itemCount: exams.length,
                  itemBuilder: (context, index) {
                    var exam = exams[index];
                    DateTime examDate = DateTime.parse(exam['date']);
                    if (isSameDay(examDate, _selectedDay)) {
                      return Card(
                        child: ListTile(
                          title: Text(
                            exam['subject'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${exam['date']} ${exam['time']}',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    } else {
                      return SizedBox.shrink(); // Hide exams for other days
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scheduleNotification,
        tooltip: 'Add Notification',
        child: Icon(Icons.notifications),
      ),
    );
  }

  Future<void> _scheduleNotification() async {
    var scheduledNotificationDateTime =
    DateTime.now().add(Duration(seconds: 5)); // Schedule notification after 5 seconds

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'channel_ID', // Channel ID
      'Channel Name', // Channel name
      importance: Importance.max,
      priority: Priority.high,
    );
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.schedule(
      0, // Notification ID
      'Потсетување за испитот', // Notification title
      'Имаш закажано испит', // Notification body
      scheduledNotificationDateTime,
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
    );
  }
}

class AddExamScreen extends StatelessWidget {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Додај испит'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(labelText: 'Предмет'),
            ),
            TextField(
              controller: _dateController,
              decoration: InputDecoration(labelText: 'Дата'),
            ),
            TextField(
              controller: _timeController,
              decoration: InputDecoration(labelText: 'Време'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Зачувај'),
              onPressed: () {
                _firestore.collection('exams').add({
                  'subject': _subjectController.text.trim(),
                  'date': _dateController.text.trim(),
                  'time': _timeController.text.trim(),
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
