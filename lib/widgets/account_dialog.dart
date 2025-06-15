import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountDialog extends StatelessWidget {
  final User? user;
  const AccountDialog({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();
    return AlertDialog(
      title: const Text('Thông tin tài khoản'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundImage: user!.photoURL != null ? NetworkImage(user!.photoURL!) : null,
            child: user!.photoURL == null ? const Icon(Icons.person, size: 32) : null,
            backgroundColor: Colors.grey[800],
          ),
          const SizedBox(height: 12),
          Text(user!.displayName ?? user!.email ?? 'No name', style: const TextStyle(fontWeight: FontWeight.bold)),
          if (user!.email != null) Text(user!.email!),
          const SizedBox(height: 8),
          Text("UID: ${user!.uid}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
        TextButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.of(context).pop();
          },
          child: const Text('Đăng xuất'),
        ),
      ],
    );
  }
}