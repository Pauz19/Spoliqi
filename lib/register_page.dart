import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isLoading = false;
  String? errorText;

  // Kiểm tra mật khẩu mạnh (ít nhất 8 ký tự, có hoa, thường, số)
  bool isPasswordStrong(String password) {
    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');
    return regex.hasMatch(password);
  }

  String mapRegisterAuthErrorToVietnamese(FirebaseAuthException e) {
    final code = e.code.toLowerCase();
    if (code == 'email-already-in-use') {
      return 'Email này đã được sử dụng cho tài khoản khác.';
    }
    if (code == 'invalid-email') {
      return 'Email không hợp lệ. Vui lòng kiểm tra lại địa chỉ email.';
    }
    if (code == 'weak-password') {
      return 'Mật khẩu chưa đủ mạnh. Hãy dùng tối thiểu 8 ký tự gồm chữ hoa, chữ thường và số.';
    }
    if (code == 'network-request-failed') {
      return 'Lỗi mạng. Vui lòng kiểm tra kết nối Internet.';
    }
    if (code == 'operation-not-allowed') {
      return 'Tài khoản email/password đang bị khóa. Liên hệ admin.';
    }
    if (code == 'too-many-requests') {
      return 'Bạn đã thao tác quá nhiều lần. Vui lòng thử lại sau.';
    }
    // Dự phòng cho trường hợp lỗi trả về dạng message
    final msg = (e.message ?? '').toLowerCase();
    if (msg.contains('email address already in use')) {
      return 'Email này đã được sử dụng cho tài khoản khác.';
    }
    if (msg.contains('badly formatted')) {
      return 'Email không hợp lệ. Vui lòng kiểm tra lại địa chỉ email.';
    }
    return e.message ?? 'Lỗi không xác định. Vui lòng thử lại!';
  }

  Future<void> _register() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });

    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        errorText = "Mật khẩu xác nhận không khớp!";
        isLoading = false;
      });
      return;
    }

    if (!isPasswordStrong(passwordController.text)) {
      setState(() {
        errorText = "Mật khẩu phải có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường và số.";
        isLoading = false;
      });
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      // Gửi email xác thực
      await userCredential.user?.sendEmailVerification();
      // Đăng xuất user ngay sau khi đăng ký (bắt buộc xác thực trước khi đăng nhập)
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      // Hiện thông báo xác thực email
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Xác thực email'),
          content: const Text(
              'Đăng ký thành công! Vui lòng kiểm tra email để xác thực tài khoản trước khi đăng nhập.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorText = mapRegisterAuthErrorToVietnamese(e);
      });
    } catch (e) {
      setState(() {
        errorText = 'Lỗi không xác định. Vui lòng thử lại!';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _goToLogin() {
    Navigator.of(context).pop(); // Quay lại trang đăng nhập
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.music_note, color: Colors.greenAccent, size: 60),
              const SizedBox(height: 16),
              const Text(
                'Đăng ký tài khoản mới',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email, color: Colors.greenAccent),
                  hintText: 'Email',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock, color: Colors.greenAccent),
                  hintText: 'Mật khẩu',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.greenAccent),
                  hintText: 'Xác nhận mật khẩu',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 16),
                Text(
                  errorText!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isLoading ? null : _register,
                  child: isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black87),
                  )
                      : const Text('Đăng ký', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: _goToLogin,
                child: const Text('Đã có tài khoản? Đăng nhập',
                    style: TextStyle(color: Colors.greenAccent)),
              ),
              const SizedBox(height: 6),
              if (!isLoading)
                const Text(
                  'Mật khẩu cần tối thiểu 8 ký tự, có chữ hoa, chữ thường và số.',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}