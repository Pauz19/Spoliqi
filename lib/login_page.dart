import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  final String? verifyEmailMsg;
  const LoginPage({super.key, this.verifyEmailMsg});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String? errorText;
  bool canResendEmail = false;

  @override
  void initState() {
    super.initState();
    if (widget.verifyEmailMsg != null) {
      errorText = widget.verifyEmailMsg;
    }
  }

  String mapAuthErrorToVietnamese(String? errorMessage) {
    if (errorMessage == null) return 'Lỗi không xác định. Vui lòng thử lại!';
    errorMessage = errorMessage.toLowerCase();
    if (errorMessage.contains('badly formatted')) {
      return 'Email không hợp lệ. Vui lòng kiểm tra lại địa chỉ email.';
    }
    if (errorMessage.contains('no user record')) {
      return 'Không tìm thấy tài khoản với email này.';
    }
    if (errorMessage.contains('password is invalid') ||
        errorMessage.contains('invalid password')) {
      return 'Sai mật khẩu. Vui lòng thử lại.';
    }
    if (errorMessage.contains('user not found')) {
      return 'Tài khoản không tồn tại.';
    }
    if (errorMessage.contains('the supplied auth credential is incorrect') ||
        errorMessage.contains('malformed or has expired')) {
      return 'Đăng nhập không thành công. Vui lòng kiểm tra lại email/mật khẩu hoặc thử đăng nhập lại.';
    }
    if (errorMessage.contains('too many unsuccessful login attempts')) {
      return 'Bạn đã đăng nhập sai quá nhiều lần. Vui lòng thử lại sau.';
    }
    if (errorMessage.contains('user disabled')) {
      return 'Tài khoản đã bị khóa.';
    }
    if (errorMessage.contains('network error')) {
      return 'Lỗi mạng. Vui lòng kiểm tra kết nối Internet.';
    }
    if (errorMessage.contains('blocked all requests from this device')) {
      return 'Thiết bị này đã bị chặn. Vui lòng thử lại sau.';
    }
    if (errorMessage.contains('email already in use')) {
      return 'Email này đã được sử dụng.';
    }
    return errorMessage; // fallback
  }

  Future<void> _login() async {
    setState(() {
      isLoading = true;
      errorText = null;
      canResendEmail = false;
    });
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      await userCredential.user?.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (!(refreshedUser?.emailVerified ?? false)) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        setState(() {
          errorText = 'Bạn cần xác thực email trước khi đăng nhập. Vui lòng kiểm tra hộp thư và xác thực!';
          canResendEmail = true;
        });
        return;
      }
      // KHÔNG điều hướng sang MainWrapper ở đây, chỉ cần dừng lại, RootScreen sẽ tự động chuyển đổi!
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        errorText = mapAuthErrorToVietnamese(e.message);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorText = 'Lỗi không xác định. Vui lòng thử lại!';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      isLoading = true;
      errorText = null;
      canResendEmail = false;
    });
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      // KHÔNG điều hướng sang MainWrapper ở đây, chỉ cần dừng lại, RootScreen sẽ tự động chuyển đổi!
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        errorText = mapAuthErrorToVietnamese(e.message);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorText = 'Lỗi đăng nhập Google.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _resendVerifyEmail() async {
    try {
      final user = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      await user.user?.sendEmailVerification();
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      setState(() {
        canResendEmail = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi lại email xác thực!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorText = 'Không thể gửi lại email xác thực. Hãy kiểm tra lại thông tin đăng nhập hoặc thử lại sau.';
      });
    }
  }

  void _goToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (_) => const ForgotPasswordDialog(),
    );
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
                'Đăng nhập Spotify Clone',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
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
              // Nút Quên mật khẩu
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading ? null : _showForgotPasswordDialog,
                  child: const Text(
                    'Quên mật khẩu?',
                    style: TextStyle(color: Color(0xFF1DB954)),
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
              if (canResendEmail)
                TextButton(
                  onPressed: isLoading ? null : _resendVerifyEmail,
                  child: const Text(
                    'Gửi lại email xác thực',
                    style: TextStyle(color: Colors.greenAccent),
                  ),
                ),
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
                  onPressed: isLoading ? null : _login,
                  child: isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black87),
                  )
                      : const Text('Đăng nhập', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.greenAccent,
                    side: const BorderSide(color: Colors.greenAccent, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Image.asset('assets/google_logo.png', width: 24, height: 24),
                  label: const Text('Đăng nhập với Google', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  onPressed: isLoading ? null : _loginWithGoogle,
                ),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: _goToRegister,
                child: const Text('Bạn chưa có tài khoản? Đăng ký',
                    style: TextStyle(color: Colors.greenAccent)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dialog đặt lại mật khẩu
class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _success;

  String mapAuthErrorToVietnamese(String? errorMessage) {
    if (errorMessage == null) return "Có lỗi xảy ra!";
    errorMessage = errorMessage.toLowerCase();
    if (errorMessage.contains('badly formatted')) {
      return 'Email không hợp lệ. Vui lòng kiểm tra lại địa chỉ email.';
    }
    if (errorMessage.contains('user not found')) {
      return 'Không tìm thấy tài khoản với email này.';
    }
    if (errorMessage.contains('network error')) {
      return 'Lỗi mạng. Vui lòng kiểm tra kết nối Internet.';
    }
    return errorMessage;
  }

  Future<void> _sendResetEmail() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      setState(() {
        _success = "Đã gửi email đặt lại mật khẩu. Vui lòng kiểm tra hộp thư.";
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = mapAuthErrorToVietnamese(e.message);
      });
    } catch (e) {
      setState(() {
        _error = "Có lỗi xảy ra!";
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
      title: const Text('Đặt lại mật khẩu'),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nhập email bạn đã đăng ký để nhận hướng dẫn đặt lại mật khẩu.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
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
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
        TextButton(
          onPressed: _isLoading ? null : _sendResetEmail,
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Gửi email'),
        ),
      ],
    );
  }
}