import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

// Hàm format thủ công nếu bạn chưa có
String manualFormat(String template, List<String> args) {
  var result = template;
  for (var i = 0; i < args.length; i++) {
    result = result.replaceAll('{$i}', args[i]);
    result = result.replaceAll('%${i + 1}\$s', args[i]);
    result = result.replaceAll('\$args{$i}', args[i]);
  }
  return result;
}

class GreetingWidget extends StatelessWidget {
  final String userName;
  const GreetingWidget({required this.userName, super.key});

  String getGreetingKey() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'greeting_morning';
    } else if (hour >= 12 && hour < 18) {
      return 'greeting_afternoon';
    } else if (hour >= 18 && hour < 22) {
      return 'greeting_evening';
    } else {
      return 'greeting_night';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      manualFormat(tr(getGreetingKey()), [userName]),
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }
}