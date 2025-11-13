import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_page.dart';
import 'home_page.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../main.dart';

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

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await _auth.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (user != null) {
        // if you require email verification, check here:
        if (!user.emailVerified) {
          Fluttertoast.showToast(msg: 'Please verify your email. Verification sent.');
          await _auth.sendEmailVerification(user);
        }
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Login error: ${e.toString()}');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purple = const Color(0xFF2A1A57);
    return Scaffold(
      backgroundColor: purple,
      body: SafeArea(
        child: Column(
          children: [
            // Header with logo area
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
                      const SizedBox(height: 8),
                      Text('Вход', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: purple, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Email
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Логин*', style: TextStyle(color: Colors.grey[700])),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              validator: (v) => (v == null || v.isEmpty) ? 'Введите email' : null,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 18),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Пароль*', style: TextStyle(color: Colors.grey[700])),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              obscureText: true,
                              validator: (v) => (v == null || v.isEmpty) ? 'Введите пароль' : null,
                            ),
                            const SizedBox(height: 24),

                            // Login button
                            SizedBox(
                              width: 180,
                              height: 44,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: purple,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                  elevation: 6,
                                ),
                                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('ВОЙТИ', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),

                            const SizedBox(height: 16),
                            // Register button
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterPage()));
                              },
                              child: const Text('Регистрация', style: TextStyle(decoration: TextDecoration.underline)),
                            )
                          ],
                        ),
                      )
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
