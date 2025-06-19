import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/notification_provider.dart';

class NotificationDialog extends StatelessWidget {
  const NotificationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.locale; // Đảm bảo rebuild khi đổi ngôn ngữ
    final notifications = context.watch<NotificationProvider>().notifications;

    return AlertDialog(
      title: Text(tr("notifications")),
      content: SizedBox(
        width: 350,
        child: notifications.isEmpty
            ? Text(tr("no_notifications_yet"))
            : ListView.separated(
          shrinkWrap: true,
          itemCount: notifications.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (_, index) {
            final n = notifications[index];
            final formattedTime = DateFormat.Hm(locale.languageCode).format(n.time);
            final formattedDate = DateFormat.yMd(locale.languageCode).format(n.time);

            String message;
            if (n.key.isNotEmpty) {
              // Đảm bảo args là List<String>
              final List<String> args = n.args.map((e) => e.toString()).toList();
              message = tr(n.key, args: args);
            } else {
              message = n.legacyMessage ?? "";
            }

            return ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(message),
              subtitle: Text(
                "$formattedTime $formattedDate",
                style: const TextStyle(fontSize: 12),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.read<NotificationProvider>().clearAll(),
          child: Text(tr("clear_all")),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr("close")),
        ),
      ],
    );
  }
}