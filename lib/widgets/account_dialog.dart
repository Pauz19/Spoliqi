import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'edit_profile_dialog.dart';

class AccountDialog extends StatefulWidget {
  const AccountDialog({super.key});

  @override
  State<AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<AccountDialog> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final displayName = user.displayName ?? user.email ?? tr('unknown_name');
    final email = user.email ?? '';
    final photoUrl = user.photoURL;
    final uid = user.uid;

    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      title: Center(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: () async {
                    final result = await showDialog(
                      context: context,
                      builder: (_) => EditProfileDialog(
                        currentName: user.displayName,
                        currentPhotoUrl: user.photoURL,
                        currentEmail: user.email,
                      ),
                    );
                    if (result == true) {
                      await FirebaseAuth.instance.currentUser?.reload();
                      setState(() {});
                      Navigator.of(context).pop(true); // TRẢ VỀ TRUE ĐỂ MAINWRAPPER nhận biết cập nhật!
                    }
                  },
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.white24,
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null
                        ? const Icon(Icons.person, size: 54, color: Colors.white54)
                        : null,
                  ),
                ),
                if (user.providerData.any((p) => p.providerId == 'google.com'))
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/google_logo.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              email,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              "UID: $uid",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      content: const SizedBox.shrink(),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white70,
          ),
          child: Text('close'.tr()),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: Colors.grey[900],
                title: Text(
                  'logout'.tr(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                content: Text(
                  'logout_confirm'.tr(),
                  style: const TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    child: Text('cancel'.tr(), style: const TextStyle(color: Colors.white54)),
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                  TextButton(
                    child: Text('logout'.tr(), style: const TextStyle(color: Colors.red)),
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                ],
              ),
            );
            if (ok == true) {
              await FirebaseAuth.instance.signOut();
              // ignore: use_build_context_synchronously
              Navigator.of(context).pop();
            }
          },
          icon: const Icon(Icons.logout, color: Colors.white),
          label: Text('logout'.tr(), style: const TextStyle(color: Colors.white, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
      ],
    );
  }
}