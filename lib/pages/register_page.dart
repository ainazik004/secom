import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await _auth.registerWithEmail(
        email: _emailCtrl.text.trim(),
        password: _pwdCtrl.text.trim(),
        fullName: _nameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
      );
      if (user != null) {
        Fluttertoast.showToast(msg: 'Registered. Verification email sent.');
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Registration error: ${e.toString()}');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purple = const Color(0xFF2A1A57);
    return Scaffold(
      appBar: AppBar(backgroundColor: purple, title: const Text('Регистрация')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Имя'), validator: (v)=> v!.isEmpty ? 'Введите имя' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email'), validator: (v)=> v!.isEmpty ? 'Введите email' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Телефон'), validator: (v)=> v!.isEmpty ? 'Введите телефон' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: _pwdCtrl, decoration: const InputDecoration(labelText: 'Пароль'), obscureText: true, validator: (v)=> v!.length < 6 ? 'Минимум 6 символов' : null),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 160,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      style: ElevatedButton.styleFrom(backgroundColor: purple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
                      child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Зарегистрироваться'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
