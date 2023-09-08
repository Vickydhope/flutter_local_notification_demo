enum NotificationType {
  normal,
  scheduled,
  image,
}

class NotificationData {
  final int id;
  final String username;
  final String message;
  final String phoneNo;
  bool hasNotification;
  final DateTime notificationTime;

  NotificationData({
    required this.id,
    required this.username,
    required this.message,
    required this.phoneNo,
    required this.hasNotification,
    required this.notificationTime,
  });

  void updateNotificationStatus(bool status) {
    hasNotification = status;
  }

  bool equals(NotificationData otherNotification) {
    return (id == otherNotification.id &&
        notificationTime == otherNotification.notificationTime);
  }

  NotificationData.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        notificationTime =
            DateTime.tryParse(json["notificationTime"]) ?? DateTime.now(),
        message = json['message'],
        username = json['username'],
        phoneNo = json['phoneNo'],
        hasNotification = json['hasNotification'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'message': message,
        'username': username,
        'hasNotification': hasNotification,
        'phoneNo': phoneNo,
        'notificationTime': notificationTime.toIso8601String(),
      };
}
