import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:easy_localization/easy_localization.dart';
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

  String mapAuthError(String? errorMessage) {
    // You can expand this map for more detailed localization support
    if (errorMessage == null) return tr('auth.unknown_error');
    errorMessage = errorMessage.toLowerCase();
    if (errorMessage.contains('badly formatted')) {
      return tr('auth.invalid_email');
    }
    if (errorMessage.contains('no user record')) {
      return tr('auth.no_user');
    }
    if (errorMessage.contains('password is invalid') ||
        errorMessage.contains('invalid password')) {
      return tr('auth.invalid_password');
    }
    if (errorMessage.contains('user not found')) {
      return tr('auth.no_user');
    }
    if (errorMessage.contains('the supplied auth credential is incorrect') ||
        errorMessage.contains('malformed or has expired')) {
      return tr('auth.login_failed');
    }
    if (errorMessage.contains('too many unsuccessful login attempts')) {
      return tr('auth.too_many_attempts');
    }
    if (errorMessage.contains('user disabled')) {
      return tr('auth.user_disabled');
    }
    if (errorMessage.contains('network error')) {
      return tr('auth.network_error');
    }
    if (errorMessage.contains('blocked all requests from this device')) {
      return tr('auth.blocked_device');
    }
    if (errorMessage.contains('email already in use')) {
      return tr('auth.email_in_use');
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
          errorText = tr('auth.verify_email');
          canResendEmail = true;
        });
        return;
      }
      // KHÔNG điều hướng sang MainWrapper ở đây, chỉ cần dừng lại, RootScreen sẽ tự động chuyển đổi!
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        errorText = mapAuthError(e.message);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorText = tr('auth.unknown_error');
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
        errorText = mapAuthError(e.message);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorText = tr('auth.google_login_error');
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
        SnackBar(content: Text(tr('auth.email_sent'))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorText = tr('auth.resend_failed');
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
                      tr('login.title'),
                      style: const TextStyle(
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
                        hintText: tr('login.email_hint'),
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
                        hintText: tr('login.password_hint'),
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
                        child: Text(
                          tr('login.forgot_password'),
                          style: const TextStyle(color: Color(0xFF1DB954)),
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
                        child: Text(
                          tr('login.resend_verify_email'),
                          style: const TextStyle(color: Colors.greenAccent),
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
                            : Text(tr('login.login_button'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                        label: Text(tr('login.with_google'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        onPressed: isLoading ? null : _loginWithGoogle,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: _goToRegister,
                      child: Text(tr('login.register_link'),
                          style: const TextStyle(color: Colors.greenAccent)),
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

  String mapAuthError(String? errorMessage) {
    if (errorMessage == null) return tr("auth.unknown_error");
    errorMessage = errorMessage.toLowerCase();
    if (errorMessage.contains('badly formatted')) {
      return tr('auth.invalid_email');
    }
    if (errorMessage.contains('user not found')) {
      return tr('auth.no_user');
    }
    if (errorMessage.contains('network error')) {
      return tr('auth.network_error');
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
        _success = tr("auth.reset_mail_sent");
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = mapAuthError(e.message);
      });
    } catch (e) {
      setState(() {
        _error = tr("auth.unknown_error");
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
      title: Text(tr('login.forgot_password_title')),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr('login.forgot_password_text'),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: tr('login.email_hint'),
                border: const OutlineInputBorder(),
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
          child: Text(tr('close')),
        ),
        TextButton(
          onPressed: _isLoading ? null : _sendResetEmail,
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text(tr('login.send_email')),
        ),
      ],
    );
  }
}