import 'dart:async';

import 'package:flutter_local_notification_demo/services/notification_data.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_service_impl.dart';

abstract class NotificationService {
  NotificationService._internal(this.flutterLocalNotificationsPlugin);

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  final didReceiveLocalNotificationStream =
      StreamController<ReceivedNotification>.broadcast();

  final selectNotificationStream = StreamController<String?>.broadcast();

  void init();

  void showNotification(
      NotificationData notificationData, String notificationMessage);

  void scheduleNotification(
      NotificationData notificationData, String notificationMessage);

  void scheduleNotificationForNextYear(
      NotificationData notificationData, String notificationMessage);

  void cancelAllNotifications();

  void handleApplicationWasLaunchedFromNotification(String payload);

  Future<List<PendingNotificationRequest>> getAllScheduledNotifications();

  void cancelNotification(NotificationData notificationData);
}
