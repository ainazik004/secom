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

        Navigator.pushReplacement(
          context,
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== PAGE TITLE =====
              Text(
                loc.registration,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2A1A57),
                ),
              ),
              const SizedBox(height: 24),

              // ===== FORM CARD =====
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [

                      _inputField(
                        controller: _nameCtrl,
                        label: loc.name,
                        validator: (v) => v!.isEmpty ? loc.enterName : null,
                      ),
                      const SizedBox(height: 16),

                      _inputField(
                        controller: _emailCtrl,
                        label: loc.email,
                        validator: (v) => v!.isEmpty ? loc.enterEmail : null,
                      ),
                      const SizedBox(height: 16),

                      _inputField(
                        controller: _phoneCtrl,
                        label: loc.phone,
                        validator: (v) => v!.isEmpty ? loc.enterPhone : null,
                      ),
                      const SizedBox(height: 16),

                      _inputField(
                        controller: _pwdCtrl,
                        label: loc.password,
                        obscure: true,
                        validator: (v) =>
                        v!.length < 6 ? loc.enterPassword : null,
                      ),

                      const SizedBox(height: 28),

                      // ===== DYNAMIC BUTTON =====
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: purple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                              : FittedBox(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12),
                              child: Text(
                                loc.registerButton,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Modern rounded input field builder
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    bool obscure = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF5F5F7),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
