import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'verify_email_page.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';

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
  final _confirmPwdCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _loading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final loc = AppLocalizations.of(context)!;
    setState(() => _loading = true);

    try {
      // Combine name + surname into fullName for AuthService
      final fullName =
      '${_nameCtrl.text.trim()} ${_surnameCtrl.text.trim()}'.trim();

      final user = await _auth.registerWithEmail(
        email: _emailCtrl.text.trim(),
        password: _pwdCtrl.text.trim(),
        fullName: fullName,
        phoneNumber: _phoneCtrl.text.trim(),
      );

      if (user != null) {
        // Create Firestore user document with all initial values
        await _createUserDocument(user);

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

  Future<void> _createUserDocument(User user) async {
    final localeCode = Localizations.localeOf(context).languageCode;
    final now = FieldValue.serverTimestamp();
    final usersRef =
    FirebaseFirestore.instance.collection('users').doc(user.uid);

    await usersRef.set({
      // Identity & auth mirror
      'uid': user.uid,
      'email': user.email ?? _emailCtrl.text.trim(),
      'displayName':
      '${_nameCtrl.text.trim()} ${_surnameCtrl.text.trim()}'.trim(),
      'firstName': _nameCtrl.text.trim(),
      'surname': _surnameCtrl.text.trim(),
      'phoneNumber': _phoneCtrl.text.trim(),
      'photoUrl': user.photoURL,
      'isEmailVerified': user.emailVerified,
      'authProvider': 'password',

      'createdAt': now,
      'lastLoginAt': now,

      // Profile / meta
      'country': null,
      'birthYear': null,
      'educationLevel': null,
      'hasCompletedOnboarding': false,
      'hasAcceptedTerms': true,
      'referralCode': null,

      // App settings
      'languageCode': localeCode,
      'theme': 'system',
      'notificationsEnabled': true,
      'soundEnabled': true,
      'vibrationEnabled': true,
      'fcmToken': null,

      // Global stats
      'totalQuestionsAnswered': 0,
      'totalCorrectAnswers': 0,
      'totalTestsCompleted': 0,
      'totalStudyTimeSeconds': 0,
      'averageScore': 0.0,
      'averageTimePerQuestionSeconds': 0.0,
      'currentStreakDays': 0,
      'longestStreakDays': 0,
      'lastTestDate': null,

      // Per-category stats
      'categoryStats': {
        'math': {
          'answered': 0,
          'correct': 0,
          'testsCompleted': 0,
          'avgScore': 0.0,
        },
        'analogy': {
          'answered': 0,
          'correct': 0,
          'testsCompleted': 0,
          'avgScore': 0.0,
        },
        'reading': {
          'answered': 0,
          'correct': 0,
          'testsCompleted': 0,
          'avgScore': 0.0,
        },
        'grammar': {
          'answered': 0,
          'correct': 0,
          'testsCompleted': 0,
          'avgScore': 0.0,
        },
      },
      'weakCategories': [],

      // Leaderboard fields
      'trophies': 0,
      'leaderboardScore': 0,
      'currentRank': null,
      'bestRank': null,
      'lastLeaderboardUpdate': now,

      // Testing / quiz preferences
      'defaultTestDurationMinutes': 60,
      'defaultQuestionsPerTest': 20,
      'shuffleQuestions': true,
      'shuffleAnswers': true,
      'showExplanationAfterEachQuestion': false,
      'showExplanationAtEnd': true,

      // Monetization
      'isPremium': false,
      'subscriptionPlan': null,
      'premiumExpiresAt': null,

      // System / technical
      'appVersion': '1.0.0',
      'platform': 'mobile',
      'lastUpdatedAt': now,
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
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
                  boxShadow: const [
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
                      // Name
                      _inputField(
                        controller: _nameCtrl,
                        label: loc.name,
                        validator: (v) =>
                        v == null || v.isEmpty ? loc.enterName : null,
                      ),
                      const SizedBox(height: 16),

                      // Surname (using plain text label, you can localize later)
                      _inputField(
                        controller: _surnameCtrl,
                        label: loc.surname,
                        validator: (v) =>
                        v == null || v.isEmpty ? loc.surname : null,
                      ),
                      const SizedBox(height: 16),

                      // Email
                      _inputField(
                        controller: _emailCtrl,
                        label: loc.email,
                        validator: (v) =>
                        v == null || v.isEmpty ? loc.enterEmail : null,
                      ),
                      const SizedBox(height: 16),

                      // Phone
                      _inputField(
                        controller: _phoneCtrl,
                        label: loc.phone,
                        validator: (v) =>
                        v == null || v.isEmpty ? loc.enterPhone : null,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      _inputField(
                        controller: _pwdCtrl,
                        label: loc.password,
                        obscure: true,
                        validator: (v) => v == null || v.length < 6
                            ? loc.enterPassword
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Confirm password
                      _inputField(
                        controller: _confirmPwdCtrl,
                        label: loc.confirmPassword,
                        obscure: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return loc.confirmPassword;
                          }
                          if (v != _pwdCtrl.text) {
                            return loc.passwordNotMatching;
                          }
                          return null;
                        },
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
                                  fontWeight: FontWeight.w600,
                                ),
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
