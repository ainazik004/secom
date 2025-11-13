import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:secom/main.dart';
import '../services/auth_service.dart';

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

    // Initial verification check
    _checkEmailVerified();

    // Poll every 3 seconds
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

      // Update Firestore
      try {
        await _auth.updateVerifiedStatus();
      } catch (_) {}

      // Navigate to MainPage (not HomePage)
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

    setState(() => _isSending = true);

    try {
      await _auth.sendEmailVerification(user);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Письмо с подтверждением отправлено!')),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final purple = const Color(0xFF2A1A57);

    return WillPopScope(
      onWillPop: () async => false, // 🚫 forbid back navigation
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: purple,
          title: const Text('Подтверждение Email'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Письмо с подтверждением отправлено.\n'
                      'Пожалуйста, проверьте свою почту.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isSending ? null : _resendVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                  ),
                  child: _isSending
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Отправить снова'),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: _checkEmailVerified,
                  child: const Text('Я подтвердил'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
