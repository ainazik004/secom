import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'verify_email_page.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:secom/gen_l10n/app_localizations.dart';


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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final loc = AppLocalizations.of(context)!;
    setState(() => _loading = true);

    try {
      final user = await _auth.registerWithEmail(
        email: _emailCtrl.text.trim(),
        password: _pwdCtrl.text.trim(),
        fullName: _nameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
      );

      if (user != null) {
        Fluttertoast.showToast(msg: loc.emailSent);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const VerifyEmailPage()),
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: e.toString(),
        toastLength: Toast.LENGTH_LONG,
      );
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
    final loc = AppLocalizations.of(context)!;
    final purple = const Color(0xFF2A1A57);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: purple,
        title: Text(loc.registration),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(labelText: loc.name),
                    validator: (v) => v!.isEmpty ? loc.enterName : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _emailCtrl,
                    decoration: InputDecoration(labelText: loc.email),
                    validator: (v) => v!.isEmpty ? loc.enterEmail : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _phoneCtrl,
                    decoration: InputDecoration(labelText: loc.phone),
                    validator: (v) => v!.isEmpty ? loc.enterPhone : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _pwdCtrl,
                    decoration: InputDecoration(labelText: loc.password),
                    obscureText: true,
                    validator: (v) =>
                    v!.length < 6 ? loc.enterPassword : null,
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: 170,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(loc.registerButton),
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
