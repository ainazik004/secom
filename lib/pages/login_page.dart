import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:secom/main.dart';
import '../services/auth_service.dart';
import 'register_page.dart';
import 'verify_email_page.dart';
import 'package:secom/gen_l10n/app_localizations.dart';

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

  // Validation error flags
  bool _emailError = false;
  bool _passwordError = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------------- Login ----------------
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

      if (user != null && user.emailVerified) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainPage()),
        );
      }
    } catch (e) {
      final msg = e.toString();

      // Detect “wrong password”
      if (msg.contains("wrong-password")) {
        setState(() => _passwordError = true);
      }

      // Detect invalid email
      if (msg.contains("invalid-email") || msg.contains("user-not-found")) {
        setState(() => _emailError = true);
      }

      // Email not verified
      if (msg.contains('verify')) {
        Fluttertoast.showToast(msg: loc.verificationRequired);

        final user = _auth.currentUser;
        if (user != null) await _auth.sendEmailVerification(user);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const VerifyEmailPage()),
        );
      } else {
        Fluttertoast.showToast(msg: msg);
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  // --------------- Forgot Password ---------------
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
                  await FirebaseAuth.instance
                      .sendPasswordResetEmail(email: email);

                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    SnackBar(content: Text(loc.resetEmailSent)),
                  );
                } catch (_) {
                  Navigator.of(dialogContext).pop();
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
    final purple = const Color(0xFF2A1A57);

    OutlineInputBorder normalBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey.shade400),
    );

    OutlineInputBorder errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.red, width: 2),
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                  child: Column(
                    children: [
                      Text(
                        loc.login,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
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
                            // Email
                            Text(loc.email,
                                style: TextStyle(color: Colors.grey[700])),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                hintText: loc.enterEmail,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                                border: normalBorder,
                                enabledBorder:
                                _emailError ? errorBorder : normalBorder,
                                focusedBorder:
                                _emailError ? errorBorder : normalBorder,
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? loc.enterEmail
                                  : null,
                            ),

                            const SizedBox(height: 18),

                            // Password
                            Text(loc.password,
                                style: TextStyle(color: Colors.grey[700])),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: loc.enterPassword,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                                border: normalBorder,
                                enabledBorder:
                                _passwordError ? errorBorder : normalBorder,
                                focusedBorder:
                                _passwordError ? errorBorder : normalBorder,
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? loc.enterPassword
                                  : null,
                            ),

                            const SizedBox(height: 8),

                            Center(
                              child: TextButton(
                                onPressed: () =>
                                    _showForgotPasswordDialog(context),
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
                                      horizontal: 40, vertical: 14),
                                  elevation: 6,
                                ),
                                child: _loading
                                    ? const CircularProgressIndicator(
                                  color: Colors.white,
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
