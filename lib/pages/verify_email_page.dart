import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'home_page.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});
  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _auth = AuthService();
  bool _isVerified = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerified();
  }

  Future<void> _checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _isVerified = user?.emailVerified ?? false;
    });
    if (_isVerified) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  Future<void> _resendVerification() async {
    setState(() => _isSending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
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
    return Scaffold(
      appBar: AppBar(backgroundColor: purple, title: const Text('Подтверждение Email')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Проверьте почту и подтвердите свой email.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSending ? null : _resendVerification,
                style: ElevatedButton.styleFrom(backgroundColor: purple),
                child: _isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Отправить снова'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkEmailVerified,
                style: ElevatedButton.styleFrom(backgroundColor: purple),
                child: const Text('Я подтвердил'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
