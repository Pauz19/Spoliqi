import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart'; // Thêm dòng này
import '../providers/notification_provider.dart'; // Thêm dòng này

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});
  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _success;

  Future<void> _handleChangePassword() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _error = tr('register.confirm_password_not_match');
        _isLoading = false;
      });
      return;
    }

    // Kiểm tra độ mạnh mật khẩu mới
    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');
    if (!regex.hasMatch(_newPasswordController.text)) {
      setState(() {
        _error = tr('register.weak_password_rule');
        _isLoading = false;
      });
      return;
    }

    try {
      if (email == null) throw Exception('No user');
      // Re-authenticate
      final cred = EmailAuthProvider.credential(
        email: email,
        password: _oldPasswordController.text,
      );
      await user!.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPasswordController.text);
      setState(() {
        _success = tr('settings.password_changed_success');
      });
      // Thêm notification
      context.read<NotificationProvider>().addNotificationKey('password_changed_success');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        setState(() {
          _error = tr('auth.invalid_password');
        });
      } else if (e.code == 'weak-password') {
        setState(() {
          _error = tr('register.weak_password_rule');
        });
      } else {
        setState(() {
          _error = tr('auth.unknown_error');
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('settings.change_password')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _oldPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: tr('settings.current_password'),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: tr('settings.new_password'),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: tr('settings.confirm_new_password'),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (_success != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _success!,
                style: const TextStyle(color: Colors.green),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(tr('close')),
        ),
        TextButton(
          onPressed: _isLoading ? null : _handleChangePassword,
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text(tr('save')),
        ),
      ],
    );
  }
}