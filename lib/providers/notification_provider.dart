import 'package:flutter/material.dart';
import '../models/app_notification.dart';

class NotificationProvider extends ChangeNotifier {
  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  /// Thêm một thông báo với key đa ngôn ngữ và arguments
  void addNotificationKey(String key, {List<String> args = const []}) {
    _notifications.insert(
      0,
      AppNotification(
        key: key,
        args: args,
        time: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  /// Xóa toàn bộ thông báo
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}