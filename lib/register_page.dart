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
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      // Gửi email xác thực
      await userCredential.user?.sendEmailVerification();
      // Đăng xuất user ngay sau khi đăng ký (bắt buộc xác thực trước khi đăng nhập)
      await FirebaseAuth.instance.signOut();
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
        errorText = e.message;
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
            ],
          ),
        ),
      ),
    );
  }
}