import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart'; // Thêm dòng này
import '../providers/notification_provider.dart'; // Thêm dòng này

class EditProfileDialog extends StatefulWidget {
  final String? currentName;
  final String? currentPhotoUrl;
  final String? currentEmail;
  const EditProfileDialog({
    super.key,
    this.currentName,
    this.currentPhotoUrl,
    this.currentEmail,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _photoUrlController;
  bool _isLoading = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName ?? "");
    _photoUrlController = TextEditingController(text: widget.currentPhotoUrl ?? "");
  }

  Future<void> _save() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      String? oldName = user?.displayName;
      String? oldPhotoUrl = user?.photoURL;
      String newName = _nameController.text.trim();
      String newPhotoUrl = _photoUrlController.text.trim();

      await user?.updateDisplayName(newName);
      await user?.updatePhotoURL(newPhotoUrl);
      await user?.reload();

      setState(() {
        _success = tr('profile.updated_success');
      });

      // Gửi thông báo nếu đổi tên hoặc avatar
      if (context.mounted) {
        if (oldName != null && oldName != newName) {
          context.read<NotificationProvider>().addNotificationKey('profile_name_changed', args: [newName]);
        }
        if (oldPhotoUrl != null && oldPhotoUrl != newPhotoUrl) {
          context.read<NotificationProvider>().addNotificationKey('profile_avatar_updated');
        }
      }

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) Navigator.pop(context, true);
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? tr('auth.unknown_error');
      });
    } catch (e) {
      setState(() {
        _error = tr('auth.unknown_error');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _changeAvatar() async {
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('profile.avatar_url')),
        content: TextField(
          controller: _photoUrlController,
          autofocus: true,
          decoration: InputDecoration(hintText: tr('profile.avatar_url')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _photoUrlController.text.trim()),
            child: Text(tr('save')),
          ),
        ],
      ),
    );
    if (url != null && url.isNotEmpty) {
      setState(() {
        _photoUrlController.text = url;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('profile.edit_profile')),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _changeAvatar,
              child: CircleAvatar(
                radius: 32,
                backgroundImage: (_photoUrlController.text.isNotEmpty)
                    ? NetworkImage(_photoUrlController.text)
                    : null,
                child: (_photoUrlController.text.isEmpty)
                    ? const Icon(Icons.person, size: 32)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: tr('profile.display_name'),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: TextEditingController(text: widget.currentEmail ?? ""),
              enabled: false,
              decoration: const InputDecoration(
                labelText: "Email",
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (_success != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_success!, style: const TextStyle(color: Colors.green)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: Text(tr('close')),
        ),
        TextButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(tr('save')),
        ),
      ],
    );
  }
}