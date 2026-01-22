import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import 'package:zhalbyrak/main.dart'; // for MainPage
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
  final _phoneCtrl = TextEditingController(text: '+996');
  final _phoneFocus = FocusNode();

  bool _loading = false;
  bool _pwdVisible = false;
  bool _confirmPwdVisible = false;

  Locale? _overrideLocale; // RU/KY only
  static const _prefKeyLocale = 'ui_locale_code';

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

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();

    _phoneFocus.addListener(() {
      if (_phoneFocus.hasFocus) {
        if (!_phoneCtrl.text.startsWith('+996')) _phoneCtrl.text = '+996';
        if (_phoneCtrl.text.length < 4) _phoneCtrl.text = '+996';
        _phoneCtrl.selection =
            TextSelection.collapsed(offset: _phoneCtrl.text.length);
      } else {
        if (_phoneCtrl.text.trim().isEmpty) _phoneCtrl.text = '+996';
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadSavedLocale() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final String? code = sp.getString(_prefKeyLocale);

      if (code == 'ru' || code == 'ky') {
        setState(() => _overrideLocale = Locale(code!));
      } else {
        setState(() => _overrideLocale = const Locale('ru'));
      }
    } catch (_) {
      if (mounted) setState(() => _overrideLocale = const Locale('ru'));
    }
  }

  Future<void> _setLocale(String code) async {
    final safe = (code == 'ky') ? 'ky' : 'ru';
    setState(() => _overrideLocale = Locale(safe));
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_prefKeyLocale, safe);
    } catch (_) {}
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final loc = AppLocalizations.of(context)!;
    setState(() => _loading = true);

    try {
      final fullName =
      '${_nameCtrl.text.trim()} ${_surnameCtrl.text.trim()}'.trim();

      final langCode = (_overrideLocale?.languageCode == 'ky') ? 'ky' : 'ru';

      try {
        await FirebaseAuth.instance.setLanguageCode(langCode);
      } catch (_) {}

      final user = await _auth.registerWithEmail(
        email: _emailCtrl.text.trim(),
        password: _pwdCtrl.text.trim(),
        fullName: fullName,
        phoneNumber: _phoneCtrl.text.trim(),
        actionCodeSettings: _emailActionCodeSettings(),
      );

      if (user == null) {
        Fluttertoast.showToast(msg: loc.unexpectedError);
        return;
      }

      Fluttertoast.showToast(msg: loc.emailSent);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyEmailGatePage(
            forcedLocale:
            (langCode == 'ky') ? const Locale('ky') : const Locale('ru'),
            pendingData: PendingUserData(
              email: _emailCtrl.text.trim(),
              displayName: fullName,
              firstName: _nameCtrl.text.trim(),
              surname: _surnameCtrl.text.trim(),
              phoneNumber: _phoneCtrl.text.trim(),
              languageCode: langCode,
            ),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(
        msg: e.message ?? e.code,
        toastLength: Toast.LENGTH_LONG,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: e.toString(),
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _phoneCtrl.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveLocale = (_overrideLocale?.languageCode == 'ky')
        ? const Locale('ky')
        : const Locale('ru');

    return Localizations.override(
      context: context,
      locale: effectiveLocale,
      child: Builder(
        builder: (context) {
          final loc = AppLocalizations.of(context)!;
          final cs = Theme.of(context).colorScheme;

          return Scaffold(
            backgroundColor: cs.background,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            loc.registration,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: cs.onBackground,
                              height: 1.1,
                            ),
                          ),
                        ),
                        _LanguageToggle(
                          current: effectiveLocale.languageCode,
                          onChanged: (code) => _setLocale(code),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      loc.createAccountSubtitle,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: cs.onBackground.withOpacity(0.72),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: cs.shadow.withOpacity(0.14),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _inputField(
                              controller: _nameCtrl,
                              label: loc.name,
                              hint: loc.nameHint,
                              prefixIcon: Icons.person_outline,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? loc.enterName
                                  : null,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),

                            _inputField(
                              controller: _surnameCtrl,
                              label: loc.surname,
                              hint: loc.surnameHint,
                              prefixIcon: Icons.badge_outlined,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? loc.enterSurname
                                  : null,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),

                            _inputField(
                              controller: _emailCtrl,
                              label: loc.email,
                              hint: loc.emailHint,
                              prefixIcon: Icons.alternate_email,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                final t = (v ?? '').trim();
                                if (t.isEmpty) return loc.enterEmail;
                                if (!t.contains('@') || !t.contains('.')) {
                                  return loc.enterValidEmail;
                                }
                                return null;
                              },
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),

                            _phoneField(loc),
                            const SizedBox(height: 14),

                            _passwordField(
                              controller: _pwdCtrl,
                              label: loc.password,
                              hint: loc.passwordHint,
                              visible: _pwdVisible,
                              onToggle: () =>
                                  setState(() => _pwdVisible = !_pwdVisible),
                              validator: (v) {
                                final t = v ?? '';
                                if (t.length < 6) return loc.enterPassword;
                                return null;
                              },
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),

                            _passwordField(
                              controller: _confirmPwdCtrl,
                              label: loc.confirmPassword,
                              hint: loc.confirmPasswordHint,
                              visible: _confirmPwdVisible,
                              onToggle: () => setState(() =>
                              _confirmPwdVisible = !_confirmPwdVisible),
                              validator: (v) {
                                final t = v ?? '';
                                if (t.isEmpty) return loc.confirmPassword;
                                if (t != _pwdCtrl.text) {
                                  return loc.passwordNotMatching;
                                }
                                return null;
                              },
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _loading ? null : _register(),
                            ),

                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: FilledButton(
                                onPressed: _loading ? null : _register,
                                style: FilledButton.styleFrom(
                                  backgroundColor: cs.primary,
                                  foregroundColor: cs.onPrimary,
                                  disabledBackgroundColor:
                                  cs.primary.withOpacity(0.6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: _loading
                                    ? SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.6,
                                    color: cs.onPrimary,
                                  ),
                                )
                                    : Text(
                                  loc.registerButton,
                                  style: const TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      loc.registerHint,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: cs.onBackground.withOpacity(0.64),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _phoneField(AppLocalizations loc) {
    const maxLen = 13; // +996 + 9 digits

    return TextFormField(
      controller: _phoneCtrl,
      focusNode: _phoneFocus,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\+?\d*$')),
        LengthLimitingTextInputFormatter(maxLen),
        _KgPhoneFormatter(),
      ],
      validator: (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty || t == '+996') return loc.enterPhone;
        final ok = RegExp(r'^\+996\d{9}$').hasMatch(t);
        if (!ok) return loc.phoneFormatError;
        return null;
      },
      decoration: _decoration(
        label: loc.phone,
        hint: loc.phoneHint996,
        prefixIcon: Icons.phone_outlined,
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      decoration: _decoration(
        label: label,
        hint: hint,
        prefixIcon: prefixIcon,
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    required bool visible,
    required VoidCallback onToggle,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      decoration: _decoration(
        label: label,
        hint: hint,
        prefixIcon: Icons.lock_outline,
        suffix: IconButton(
          onPressed: onToggle,
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
        ),
      ),
    );
  }

  InputDecoration _decoration({
    required String label,
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    final cs = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: cs.surfaceVariant,
      prefixIcon: Icon(prefixIcon, color: cs.primary),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.outline, width: 1.2),
      ),
    );
  }
}

/// After verification: create Firestore doc, then go Home and clear stack.
class VerifyEmailGatePage extends StatefulWidget {
  final Locale forcedLocale; // RU/KY only
  final PendingUserData pendingData;

  const VerifyEmailGatePage({
    super.key,
    required this.forcedLocale,
    required this.pendingData,
  });

  @override
  State<VerifyEmailGatePage> createState() => _VerifyEmailGatePageState();
}

class _VerifyEmailGatePageState extends State<VerifyEmailGatePage> {
  Timer? _timer;
  bool _checking = false;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _checkVerified(silent: true);
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkVerified(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    final loc = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Fluttertoast.showToast(msg: loc.unexpectedError);
      return;
    }

    try {
      await FirebaseAuth.instance
          .setLanguageCode(widget.forcedLocale.languageCode);
    } catch (_) {}

    try {
      await user.sendEmailVerification(ActionCodeSettings(
        url: 'https://zhalbyrak.app/verify.html',
        handleCodeInApp: false,
        androidPackageName: 'com.android.zhalbyrak',
        androidInstallApp: true,
        androidMinimumVersion: '1',
        iOSBundleId: 'com.ios.zhalbyrak',
      ));

      Fluttertoast.showToast(msg: loc.emailSent);
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(
        msg: e.message ?? e.code,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  Future<void> _checkVerified({required bool silent}) async {
    if (_checking) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _timer?.cancel();
      if (!silent) {
        final loc = AppLocalizations.of(context)!;
        Fluttertoast.showToast(
          msg: loc.unexpectedError,
          toastLength: Toast.LENGTH_LONG,
        );
      }
      return;
    }

    setState(() => _checking = true);

    try {
      await user.reload();
      final refreshed = FirebaseAuth.instance.currentUser;

      final isVerified = refreshed?.emailVerified == true;

      if (isVerified && refreshed != null) {
        _timer?.cancel();

        await _createUserDocumentAfterVerification(refreshed);

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainPage()),
              (_) => false,
        );
      }

      if (!silent) {
        final loc = AppLocalizations.of(context)!;
        Fluttertoast.showToast(msg: loc.notVerifiedYet);
      }
    } catch (e) {
      if (!silent) {
        Fluttertoast.showToast(msg: e.toString(), toastLength: Toast.LENGTH_LONG);
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _createUserDocumentAfterVerification(User user) async {
    if (_creating) return;

    setState(() => _creating = true);

    final usersRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(usersRef);

      final now = FieldValue.serverTimestamp();

      if (snap.exists) {
        tx.set(usersRef, {
          'isEmailVerified': true,
          'emailVerified': true,
          'lastLoginAt': now,
        }, SetOptions(merge: true));
        return;
      }

      tx.set(usersRef, {
        'uid': user.uid,
        'email': user.email ?? widget.pendingData.email,
        'displayName': widget.pendingData.displayName,
        'firstName': widget.pendingData.firstName,
        'surname': widget.pendingData.surname,
        'phoneNumber': widget.pendingData.phoneNumber,
        'photoUrl': user.photoURL,
        'isEmailVerified': true,
        'emailVerified': true,
        'authProvider': 'password',
        'createdAt': now,
        'lastLoginAt': now,
        'country': null,
        'birthYear': null,
        'educationLevel': null,
        'hasCompletedOnboarding': false,
        'hasAcceptedTerms': true,
        'referralCode': null,
        'languageCode': widget.pendingData.languageCode,
        'theme': 'system',
        'notificationsEnabled': true,
        'soundEnabled': true,
        'vibrationEnabled': true,
        'fcmToken': null,
        'totalQuestionsAnswered': 0,
        'totalCorrectAnswers': 0,
        'totalTestsCompleted': 0,
        'totalStudyTimeSeconds': 0,
        'averageScore': 0.0,
        'averageTimePerQuestionSeconds': 0.0,
        'currentStreakDays': 0,
        'longestStreakDays': 0,
        'lastTestDate': null,
        'categoryStats': {
          'math': {'answered': 0, 'correct': 0, 'testsCompleted': 0, 'avgScore': 0.0},
          'analogy': {'answered': 0, 'correct': 0, 'testsCompleted': 0, 'avgScore': 0.0},
          'reading': {'answered': 0, 'correct': 0, 'testsCompleted': 0, 'avgScore': 0.0},
          'grammar': {'answered': 0, 'correct': 0, 'testsCompleted': 0, 'avgScore': 0.0},
        },
        'weakCategories': [],
        'trophies': 0,
        'leaderboardScore': 0,
        'currentRank': null,
        'bestRank': null,
        'lastLeaderboardUpdate': now,
        'defaultTestDurationMinutes': 60,
        'defaultQuestionsPerTest': 20,
        'shuffleQuestions': true,
        'shuffleAnswers': true,
        'showExplanationAfterEachQuestion': false,
        'showExplanationAtEnd': true,
        'isPremium': false,
        'subscriptionPlan': null,
        'premiumExpiresAt': null,
        'appVersion': '1.0.0',
        'platform': 'mobile',
        'lastUpdatedAt': now,
      }, SetOptions(merge: true));
    });

    if (mounted) setState(() => _creating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      context: context,
      locale: widget.forcedLocale,
      child: Builder(
        builder: (context) {
          final loc = AppLocalizations.of(context)!;
          final cs = Theme.of(context).colorScheme;

          return WillPopScope(
            onWillPop: () async => false,
            child: Scaffold(
              backgroundColor: cs.background,
              appBar: AppBar(
                backgroundColor: cs.background,
                elevation: 0,
                surfaceTintColor: cs.background,
                automaticallyImplyLeading: false,
                title: Text(
                  loc.verifyEmailTitle,
                  style: TextStyle(
                    color: cs.onBackground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              body: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.verifyEmailSubtitle,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: cs.onBackground.withOpacity(0.72),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.pendingData.email,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed:
                        _creating ? null : () => _checkVerified(silent: false),
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          disabledBackgroundColor: cs.primary.withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: (_checking || _creating)
                            ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            color: cs.onPrimary,
                          ),
                        )
                            : Text(
                          loc.iVerifiedButton,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: _creating ? null : _resend,
                      child: Text(
                        loc.resendEmailButton,
                        style: TextStyle(
                          color: cs.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const Spacer(),

                    Text(
                      loc.verifyEmailHint,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: cs.onBackground.withOpacity(0.64),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PendingUserData {
  final String email;
  final String displayName;
  final String firstName;
  final String surname;
  final String phoneNumber;
  final String languageCode; // 'ru' or 'ky'

  PendingUserData({
    required this.email,
    required this.displayName,
    required this.firstName,
    required this.surname,
    required this.phoneNumber,
    required this.languageCode,
  });
}

/// Keeps phone always starting with +996 and prevents deleting prefix.
class _KgPhoneFormatter extends TextInputFormatter {
  static const _prefix = '+996';

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    var text = newValue.text;

    if (text.isEmpty) {
      text = _prefix;
    } else {
      if (!text.startsWith('+')) text = '+$text';

      if (!text.startsWith(_prefix)) {
        final digits = text.replaceAll(RegExp(r'[^\d]'), '');
        if (digits.startsWith('996')) {
          text = '+$digits';
        } else {
          final tail = digits.replaceFirst(RegExp(r'^996'), '');
          text = _prefix + tail;
        }
      }
    }

    var selectionIndex = newValue.selection.end;
    if (selectionIndex < _prefix.length) selectionIndex = _prefix.length;
    if (selectionIndex > text.length) selectionIndex = text.length;

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  final String current; // 'ru' or 'ky'
  final ValueChanged<String> onChanged;

  const _LanguageToggle({
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selected = (current == 'ky') ? 'ky' : 'ru';

    Widget chip(String code, String label, bool active) {
      return InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onChanged(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? cs.primary : cs.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? cs.primary : cs.outlineVariant,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: active ? cs.onPrimary : cs.onSurface,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          chip('ru', 'RU', selected == 'ru'),
          const SizedBox(width: 6),
          chip('ky', 'KY', selected == 'ky'),
        ],
      ),
    );
  }
}
