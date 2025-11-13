import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:secom/main.dart';
import '../services/auth_service.dart';
import 'package:secom/gen_l10n/app_localizations.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _auth = AuthService();
  Timer? _timer;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    _checkEmailVerified(); // immediate check

    _timer = Timer.periodic(
      const Duration(seconds: 3),
          (_) => _checkEmailVerified(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// ------------------------------------------------------------
  /// 🔹 Check if email is verified
  /// ------------------------------------------------------------
  Future<void> _checkEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await user.reload();
    final refreshed = FirebaseAuth.instance.currentUser!;

    if (refreshed.emailVerified) {
      _timer?.cancel();

      try {
        await _auth.updateVerifiedStatus();
      } catch (_) {}

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainPage()),
        );
      }
    }
  }

  /// ------------------------------------------------------------
  /// 🔹 Resend verification email
  /// ------------------------------------------------------------
  Future<void> _resendVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final loc = AppLocalizations.of(context)!;

    setState(() => _isSending = true);

    try {
      await _auth.sendEmailVerification(user);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.emailSent)),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final purple = const Color(0xFF2A1A57);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: purple,
          title: Text(loc.confirmEmail),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  loc.emailSent,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isSending ? null : _resendVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                  ),
                  child: _isSending
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(loc.resend),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: _checkEmailVerified,
                  child: Text(loc.iVerified),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
