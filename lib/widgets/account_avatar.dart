import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'account_dialog.dart';

class AccountAvatar extends StatelessWidget {
  const AccountAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final avatarUrl = user?.photoURL;
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AccountDialog(user: user),
        );
      },
      child: CircleAvatar(
        radius: 20,
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
        backgroundColor: Colors.grey[800],
      ),
    );
  }
}