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
      // if (!mounted) return;
      // Navigator.of(context).pushReplacement(
      //   MaterialPageRoute(builder: (_) => const MainWrapper()),
      // );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        errorText = e.message;
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
      // if (!mounted) return;
      // Navigator.of(context).pushReplacement(
      //   MaterialPageRoute(builder: (_) => const MainWrapper()),
      // );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        errorText = e.message;
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