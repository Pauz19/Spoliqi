import 'package:flutter/material.dart';
import 'auth_service.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key}); // Thêm const constructor

  @override
  Widget build(BuildContext context) {
    final AuthService _authService = AuthService();

    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          icon: Icon(Icons.login),
          label: const Text('Đăng nhập bằng Google'),
          onPressed: () async {
            final user = await _authService.signInWithGoogle();
            if (user != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đăng nhập thành công: ${user.user?.displayName}')),
              );
              // Không cần chuyển trang nếu sử dụng StreamBuilder ở main.dart
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đăng nhập thất bại hoặc bị hủy')),
              );
            }
          },
        ),
      ),
    );
  }
}