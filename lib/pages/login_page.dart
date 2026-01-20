import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import 'register_page.dart';
import 'home_page.dart';
import 'verify_email_page.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _auth = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _emailError = false;
  bool _passwordError = false;
  bool _passwordVisible = false;

  DateTime? _lastResendAt;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  ActionCodeSettings _emailActionCodeSettings() {
    return ActionCodeSettings(
      url: 'https://zhalbyrak.app/verify.html',
      handleCodeInApp: false,
      androidPackageName: 'com.android.zhalbyrak',
      androidInstallApp: true,
      androidMinimumVersion: '1',
      iOSBundleId: 'com.ios.zhalbyrak',
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _emailError = false;
      _passwordError = false;
    });

    final loc = AppLocalizations.of(context)!;

    try {
      final user = await _auth.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (user == null) {
        throw Exception('null user');
      }

      // Refresh auth state
      await user.reload();
      final refreshed = FirebaseAuth.instance.currentUser;
      if (refreshed == null) {
        throw Exception('null refreshed user');
      }

      // ✅ Verified → go Home
      if (refreshed.emailVerified) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
              (_) => false,
        );
        return;
      }

      // ✅ Not verified → route to VerifyEmailPage
      Fluttertoast.showToast(msg: loc.verificationRequired);

      // Optional resend with cooldown (30s)
      final now = DateTime.now();
      final canResend = _lastResendAt == null ||
          now.difference(_lastResendAt!).inSeconds >= 30;

      if (canResend) {
        final lang = Localizations.localeOf(context).languageCode;
        try {
          await _auth.sendEmailVerification(
            actionCodeSettings: _emailActionCodeSettings(),
            languageCode: (lang == 'ky') ? 'ky' : (lang == 'ru') ? 'ru' : 'en',
          );
          _lastResendAt = now;
        } catch (_) {
          // Non-fatal
        }
      }

      if (!mounted) return;

      // Important: no pending data here (login flow). Verify page can work without it.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const VerifyEmailPage()),
      );
    } catch (_) {
      setState(() {
        _emailError = true;
        _passwordError = true;
      });

      Fluttertoast.showToast(msg: loc.invalidEmailOrPassword);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showForgotPasswordDialog(BuildContext rootContext) async {
    final loc = AppLocalizations.of(rootContext)!;
    final emailCtrl = TextEditingController();

    await showDialog(
      context: rootContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(loc.resetPassword),
          content: TextField(
            controller: emailCtrl,
            decoration: InputDecoration(
              labelText: loc.email,
              hintText: loc.enterEmail,
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(loc.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailCtrl.text.trim();
                if (email.isEmpty) {
                  Fluttertoast.showToast(msg: loc.enterEmail);
                  return;
                }

                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();

                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    SnackBar(content: Text(loc.resetEmailSent)),
                  );
                } catch (_) {
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();

                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    SnackBar(content: Text(loc.resetFailed)),
                  );
                }
              },
              child: Text(loc.send),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    const purple = Color(0xFF2A1A57);

    final normalBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey.shade400),
    );

    const errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: Colors.red, width: 2),
    );

    return Scaffold(
      backgroundColor: purple,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: Center(
                child: Image.asset('assets/secom_logo.png', height: 80),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                  child: Column(
                    children: [
                      Text(
                        loc.login,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loc.email, style: TextStyle(color: Colors.grey[700])),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              onChanged: (_) {
                                if (_emailError || _passwordError) {
                                  setState(() {
                                    _emailError = false;
                                    _passwordError = false;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                hintText: loc.enterEmail,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                border: normalBorder,
                                enabledBorder: _emailError ? errorBorder : normalBorder,
                                focusedBorder: _emailError ? errorBorder : normalBorder,
                                errorText: _emailError ? loc.invalidEmailOrPassword : null,
                              ),
                              validator: (v) =>
                              (v == null || v.isEmpty) ? loc.enterEmail : null,
                            ),
                            const SizedBox(height: 18),
                            Text(loc.password, style: TextStyle(color: Colors.grey[700])),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_passwordVisible,
                              onChanged: (_) {
                                if (_passwordError || _emailError) {
                                  setState(() {
                                    _emailError = false;
                                    _passwordError = false;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                hintText: loc.enterPassword,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                border: normalBorder,
                                enabledBorder: _passwordError ? errorBorder : normalBorder,
                                focusedBorder: _passwordError ? errorBorder : normalBorder,
                                errorText: _passwordError ? loc.invalidEmailOrPassword : null,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _passwordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.grey[700],
                                  ),
                                  onPressed: () => setState(
                                          () => _passwordVisible = !_passwordVisible),
                                ),
                              ),
                              validator: (v) =>
                              (v == null || v.isEmpty) ? loc.enterPassword : null,
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton(
                                onPressed: () => _showForgotPasswordDialog(context),
                                child: Text(
                                  loc.forgotPassword,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: ElevatedButton(
                                onPressed: _loading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: purple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 14,
                                  ),
                                  elevation: 6,
                                ),
                                child: _loading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.4,
                                  ),
                                )
                                    : Text(
                                  loc.loginButton,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterPage(),
                                    ),
                                  );
                                },
                                child: Text(
                                  loc.register,
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
