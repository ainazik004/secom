import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import 'register_page.dart';
import 'verify_email_page.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';
import 'package:zhalbyrak/main.dart';

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

      await user.reload();
      final refreshed = FirebaseAuth.instance.currentUser;
      if (refreshed == null) {
        throw Exception('null refreshed user');
      }

      if (refreshed.emailVerified) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainPage()),
              (_) => false,
        );
        return;
      }

      Fluttertoast.showToast(msg: loc.verificationRequired);

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
          // non-fatal
        }
      }

      if (!mounted) return;

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
        final cs = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surface,
          surfaceTintColor: cs.surface,
          title: Text(loc.resetPassword, style: TextStyle(color: cs.onSurface)),
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
            FilledButton(
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
    final cs = Theme.of(context).colorScheme;

    // Brand purple for the header panel (uses your scheme, works in both modes)
    final headerPurple = cs.primaryContainer; // dark: zPurple, light: light container

    final normalBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: cs.outlineVariant),
    );

    final errorBorder = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: cs.error, width: 2),
    );

    return Scaffold(
      backgroundColor: headerPurple,
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
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                  child: Column(
                    children: [
                      Text(
                        loc.login,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.email,
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
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
                                enabledBorder:
                                _emailError ? errorBorder : normalBorder,
                                focusedBorder:
                                _emailError ? errorBorder : normalBorder,
                                errorText:
                                _emailError ? loc.invalidEmailOrPassword : null,
                              ),
                              validator: (v) =>
                              (v == null || v.isEmpty) ? loc.enterEmail : null,
                            ),
                            const SizedBox(height: 18),
                            Text(
                              loc.password,
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
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
                                enabledBorder:
                                _passwordError ? errorBorder : normalBorder,
                                focusedBorder:
                                _passwordError ? errorBorder : normalBorder,
                                errorText: _passwordError
                                    ? loc.invalidEmailOrPassword
                                    : null,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _passwordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  onPressed: () => setState(
                                          () => _passwordVisible = !_passwordVisible),
                                ),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? loc.enterPassword
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton(
                                onPressed: () => _showForgotPasswordDialog(context),
                                child: Text(
                                  loc.forgotPassword,
                                  style: TextStyle(
                                    color: cs.secondary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: FilledButton(
                                onPressed: _loading ? null : _login,
                                style: FilledButton.styleFrom(
                                  backgroundColor: cs.primary,
                                  foregroundColor: cs.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 14,
                                  ),
                                ),
                                child: _loading
                                    ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: cs.onPrimary,
                                    strokeWidth: 2.4,
                                  ),
                                )
                                    : Text(
                                  loc.loginButton,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
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
                                  style: TextStyle(
                                    color: cs.onSurface,
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
