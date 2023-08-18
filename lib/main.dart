import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notification_demo/pages/notification_page.dart';
import 'package:flutter_local_notification_demo/pages/scheduled_notification_page.dart';
import 'package:flutter_local_notification_demo/services/notification_data.dart';
import 'package:flutter_local_notification_demo/services/notification_service.dart';
import 'package:flutter_local_notification_demo/services/notification_service_impl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final NotificationService _notificationService = NotificationServiceImpl();

  String? selectedNotificationPayload;

  @override
  void initState() {
    _notificationService.init();
    _configureDidReceiveLocalNotificationSubject();
    _configureSelectNotificationSubject();

    checkNotificationLaunchDetails();
    super.initState();
  }

  checkNotificationLaunchDetails() async {
    final notificationAppLaunchDetails = !kIsWeb && Platform.isLinux
        ? null
        : await (_notificationService as NotificationServiceImpl)
            .flutterLocalNotificationsPlugin
            .getNotificationAppLaunchDetails();

    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      selectedNotificationPayload =
          notificationAppLaunchDetails!.notificationResponse?.payload;
      setState(() {});

      _handleNotification(
          notificationAppLaunchDetails.notificationResponse?.payload ?? '');
    }
  }

  _handleNotification(String payload) {
    final NotificationData notificationData =
        NotificationData.fromJson(jsonDecode(payload));

    if (notificationData.id == 1) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => const NotificationPage(),
      ));
    }

    if (notificationData.id == 2) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => const ScheduledNotificationPage(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Notification Demo"),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () {
                _notificationService.scheduleNotification(
                    NotificationData(
                      id: 2,
                      username: "Doops",
                      message: "Quick brown fox jumps over the lazy dog!",
                      phoneNo: "9988776655",
                      hasNotification: false,
                      notificationTime:
                          DateTime.now().add(const Duration(seconds: 10)),
                    ),
                    "Quick brown fox jumps over the lazy dog!");
              },
              child: const Text("Schedule notification"),
            ),
            OutlinedButton(
              onPressed: () {
                _notificationService.showNotification(
                    NotificationData(
                      id: 1,
                      username: "Doops",
                      message: "Quick brown fox jumps over the lazy dog!",
                      phoneNo: "9988776655",
                      hasNotification: false,
                      notificationTime:
                          DateTime.now().add(const Duration(seconds: 10)),
                    ),
                    "Quick brown fox jumps over the lazy dog!");
              },
              child: const Text("Show notification"),
            ),
            OutlinedButton(
              onPressed: () {
                (_notificationService as NotificationServiceImpl)
                    .showNotificationWithClippedThumbnailAttachment();
              },
              child: const Text("Image notification"),
            ),
            Text(selectedNotificationPayload ?? "")
          ],
        ),
      ),
    );
  }

  void _configureDidReceiveLocalNotificationSubject() {
    _notificationService.selectNotificationStream.stream
        .listen((String? payload) async {
      print("DidReceiveLocalNotification : $payload");

      if (payload != null && payload.isNotEmpty) {
        _handleNotification(payload ?? '');
      }
    });
  }

  void _configureSelectNotificationSubject() {
    _notificationService.didReceiveLocalNotificationStream.stream
        .listen((ReceivedNotification receivedNotification) async {
      print("SelectNotification : ${receivedNotification.payload}");

      await showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: receivedNotification.title != null
              ? Text(receivedNotification.title!)
              : null,
          content: receivedNotification.body != null
              ? Text(receivedNotification.body!)
              : null,
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {},
              child: const Text('Ok'),
            )
          ],
        ),
      );
    });
  }
}
