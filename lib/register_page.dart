import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

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

  String mapRegisterAuthError(FirebaseAuthException e) {
    final code = e.code.toLowerCase();
    if (code == 'email-already-in-use') {
      return tr('register.email_in_use');
    }
    if (code == 'invalid-email') {
      return tr('register.invalid_email');
    }
    if (code == 'weak-password') {
      return tr('register.weak_password');
    }
    if (code == 'network-request-failed') {
      return tr('register.network_error');
    }
    if (code == 'operation-not-allowed') {
      return tr('register.operation_not_allowed');
    }
    if (code == 'too-many-requests') {
      return tr('register.too_many_requests');
    }
    // Dự phòng cho trường hợp lỗi trả về dạng message
    final msg = (e.message ?? '').toLowerCase();
    if (msg.contains('email address already in use')) {
      return tr('register.email_in_use');
    }
    if (msg.contains('badly formatted')) {
      return tr('register.invalid_email');
    }
    return e.message ?? tr('register.unknown_error');
  }

  Future<void> _register() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });

    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        errorText = tr('register.confirm_password_not_match');
        isLoading = false;
      });
      return;
    }

    if (!isPasswordStrong(passwordController.text)) {
      setState(() {
        errorText = tr('register.weak_password_rule');
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
          title: Text(tr('register.verify_email_title')),
          content: Text(tr('register.verify_email_content')),
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
        errorText = mapRegisterAuthError(e);
      });
    } catch (e) {
      setState(() {
        errorText = tr('register.unknown_error');
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

  void _changeLanguage(Locale locale) {
    context.setLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.music_note, color: Colors.greenAccent, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      tr('register.title'),
                      style: const TextStyle(
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
                        hintText: tr('register.email_hint'),
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
                        hintText: tr('register.password_hint'),
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
                        hintText: tr('register.confirm_password_hint'),
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
                            : Text(tr('register.button'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: _goToLogin,
                      child: Text(tr('register.login_link'),
                          style: const TextStyle(color: Colors.greenAccent)),
                    ),
                    const SizedBox(height: 6),
                    if (!isLoading)
                      Text(
                        tr('register.password_rule'),
                        style: const TextStyle(color: Colors.white38, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
            // Language picker at top right
            Positioned(
              right: 16,
              top: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Locale>(
                      value: context.locale,
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.white),
                      iconEnabledColor: Colors.greenAccent,
                      items: [
                        DropdownMenuItem(
                          value: const Locale('en'),
                          child: const Text('English', style: TextStyle(color: Colors.white)),
                        ),
                        DropdownMenuItem(
                          value: const Locale('vi'),
                          child: const Text('Tiếng Việt', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                      onChanged: (locale) {
                        if (locale != null) _changeLanguage(locale);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}