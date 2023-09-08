import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notification_demo/services/notification_data.dart';
import 'package:flutter_local_notification_demo/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show Directory, File, Platform;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:http/http.dart' as http;

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // ignore: avoid_print
  print('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    // ignore: avoid_print
    print(
        'notification action tapped with input: ${notificationResponse.input}');
  }
}

class NotificationServiceImpl implements NotificationService {
  @override
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  final didReceiveLocalNotificationStream =
  StreamController<ReceivedNotification>.broadcast();

  @override
  final selectNotificationStream = StreamController<String?>.broadcast();

  String? selectedNotificationPayload;

  @override
  void init() async {
    await _configLocalTimezone();

    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings("img");

    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) {
        didReceiveLocalNotificationStream.add(
          ReceivedNotification(
            id: id,
            title: title,
            body: body,
            payload: payload,
          ),
        );
      },
    );

    final InitializationSettings initializationSettings =
    InitializationSettings(
      android: androidInitializationSettings,
      iOS: initializationSettingsIOS,
      macOS: null,
    );

    initializeLocalNotificationPlugin(initializationSettings);
  }

  ///Initialize local notification plugin
  void initializeLocalNotificationPlugin(
      InitializationSettings initializationSettings,) {
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (notificationResponse) {
        switch (notificationResponse.notificationResponseType) {
          case NotificationResponseType.selectedNotification:
            selectNotificationStream.add(notificationResponse.payload);
            break;
          case NotificationResponseType.selectedNotificationAction:
            if (notificationResponse.actionId == "navigationActionId") {
              selectNotificationStream.add(notificationResponse.payload);
            }
            break;
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  @override
  Future<List<PendingNotificationRequest>> getAllScheduledNotifications() {
    throw UnimplementedError();
  }

  @override
  void showNotification(NotificationData notificationData,
      String notificationMessage) async {
    await flutterLocalNotificationsPlugin.show(
      notificationData.hashCode,
      "Notifier",
      notificationMessage,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          actions: [
            AndroidNotificationAction("1", "Open", showsUserInterface: true),
            AndroidNotificationAction("2", "Close", cancelNotification: true),
          ],
          "channel_id",
          "Notification Demo",
          channelDescription:
          "Notification to showing demo for local notification in flutter",
          importance: Importance.max,
        ),
        iOS: DarwinNotificationDetails(
          attachments: [],
          threadIdentifier: "thread_id",
        ),
      ),
      payload: jsonEncode(notificationData),
    );
  }

  @override
  void scheduleNotification(NotificationData notificationData,
      String notificationMessage) {
    flutterLocalNotificationsPlugin.zonedSchedule(
      notificationData.id,
      "Quick brown story",
      notificationMessage,
      _convertTime(
        notificationData.notificationTime.hour,
        notificationData.notificationTime.minute,
        notificationData.notificationTime.second,
      ),
      const NotificationDetails(
        android: AndroidNotificationDetails("channel_id", "Notification Demo",
            channelDescription:
            "Notification to showing demo for local notification in flutter ",
            importance: Importance.high),
        iOS: DarwinNotificationDetails(
          threadIdentifier: "thread_id",
        ),
      ),
      payload: jsonEncode(notificationData),
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  void handleApplicationWasLaunchedFromNotification(String payload) async {
    if (Platform.isIOS) {
      _rescheduleNotificationFromPayload(payload);
      return;
    }

    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
    await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    if (notificationAppLaunchDetails != null &&
        notificationAppLaunchDetails.didNotificationLaunchApp) {
      _rescheduleNotificationFromPayload(
          notificationAppLaunchDetails.notificationResponse?.payload ?? "");
    }
  }

  @override
  void cancelNotification(NotificationData notificationData) async {
    await flutterLocalNotificationsPlugin.cancel(notificationData.hashCode);
  }

  @override
  void cancelAllNotifications() {
    flutterLocalNotificationsPlugin.cancelAll();
  }

  void _rescheduleNotificationFromPayload(String payload) {
    print("Reschedule : $payload");
  }

  NotificationData getNotificationDataFromPayload(String payload) {
    Map<String, dynamic> json = jsonDecode(payload);
    NotificationData notificationData = NotificationData.fromJson(json);
    return notificationData;
  }

  @override
  void scheduleNotificationForNextYear(NotificationData notificationData,
      String notificationMessage) {}

  tz.TZDateTime _convertTime(int hour, int minute, int sec) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduleDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
        sec);
    if (scheduleDate.isBefore(now)) {
      scheduleDate = scheduleDate.add(const Duration(days: 1));
    }

    return scheduleDate;
  }

  Future<void> _configLocalTimezone() async {
    tz.initializeTimeZones();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));
  }

  Future<void> showLargeIconNotification() async {
    final String largeIconPath =
    await _downloadAndSaveFile('https://dummyimage.com/48x48', 'largeIcon');
    final String bigPicturePath = await _downloadAndSaveFile(
        'https://images.unsplash.com/photo-1529665253569-6d01c0eaf7b6?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8cHJvZmlsZXxlbnwwfHwwfHx8MA%3D%3D&w=1000&q=80',
        'bigPicture.jpg');

    final BigPictureStyleInformation bigPictureStyleInformation =
    BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath),
      largeIcon: FilePathAndroidBitmap(largeIconPath),
      contentTitle: 'overridden <b>big</b> content title',
      htmlFormatContentTitle: true,
      summaryText: 'summary <i>text</i>',
      htmlFormatSummaryText: true,
    );
    final AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'big text channel id',
      'big text channel name',
      channelDescription: 'big text channel description',
      styleInformation: bigPictureStyleInformation,
    );

    final darwinNotificationDetails = DarwinNotificationDetails(
      threadIdentifier: "bigPicture",
      attachments: [
        DarwinNotificationAttachment(bigPicturePath, hideThumbnail: false),
      ],
    );
    final NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails, iOS: darwinNotificationDetails);
    await flutterLocalNotificationsPlugin.show(
      id++,
      'big text title',
      'silent body',
      notificationDetails,
    );
  }

  Future<void> showNotificationWithAttachment({
    required bool hideThumbnail,
  }) async {
    final String bigPicturePath = await _downloadAndSaveFile(
        'https://images.unsplash.com/photo-1529665253569-6d01c0eaf7b6?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8cHJvZmlsZXxlbnwwfHwwfHx8MA%3D%3D&w=1000&q=80',
        'bigPicture.jpg');
    final DarwinNotificationDetails darwinNotificationDetails =
    DarwinNotificationDetails(
      attachments: <DarwinNotificationAttachment>[
        DarwinNotificationAttachment(
          bigPicturePath,
          hideThumbnail: hideThumbnail,
        )
      ],
    );
    final NotificationDetails notificationDetails = NotificationDetails(
        iOS: darwinNotificationDetails, macOS: darwinNotificationDetails);
    await flutterLocalNotificationsPlugin.show(
        id++,
        'notification with attachment title',
        'notification with attachment body',
        notificationDetails);
  }

  Future<void> showNotificationWithClippedThumbnailAttachment() async {
    var imagePath = "https://images.unsplash.com/photo-1529665253569-6d01c0eaf7b6?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8cHJvZmlsZXxlbnwwfHwwfHx8MA%3D%3D&w=1000&q=80";

    final String bigPicturePath = await _downloadAndSaveFile(
        imagePath, 'bigPicture.jpg');

    final BigPictureStyleInformation bigPictureStyleInformation =
    BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath),
      largeIcon: FilePathAndroidBitmap(bigPicturePath),
      contentTitle: 'overridden <b>big</b> content title',
      htmlFormatContentTitle: true,
      summaryText: 'summary <i>text</i>',
      htmlFormatSummaryText: true,
    );

    final AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
        'big text channel id', 'big text channel name',
        channelDescription: 'big text channel description',
        styleInformation: bigPictureStyleInformation,
        importance: Importance.max);

    final DarwinNotificationDetails darwinNotificationDetails =
    DarwinNotificationDetails(
      attachments: <DarwinNotificationAttachment>[
        DarwinNotificationAttachment(
          bigPicturePath,
          thumbnailClippingRect:
          // lower right quadrant of the attachment
          const DarwinNotificationAttachmentThumbnailClippingRect(
            x: 0.5,
            y: 0.5,
            height: 0.5,
            width: 0.5,
          ),
        )
      ],
    );
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
      macOS: darwinNotificationDetails,
    );
    await flutterLocalNotificationsPlugin.show(
        id++,
        'notification with attachment title',
        'notification with attachment body',
        notificationDetails,
        payload: imagePath
    );
  }

  int id = 0;

  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getTemporaryDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }
}

Future selectNotification(NotificationResponse? notificationResponse) async {
  print(notificationResponse?.payload ?? "");

  return notificationResponse?.payload;
}
