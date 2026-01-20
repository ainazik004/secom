import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import 'package:zhalbyrak/main.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';

class VerifyEmailPage extends StatefulWidget {
  final PendingUserData? pending;

  const VerifyEmailPage({
    super.key,
    this.pending,
  });

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _auth = AuthService();

  Timer? _timer;
  bool _checking = false;
  bool _sending = false;
  bool _completed = false;

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

    _checkEmailVerified(silent: true);
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkEmailVerified(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified({required bool silent}) async {
    if (_checking || _completed) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _checking = true);

    try {
      await user.reload();
      final refreshed = FirebaseAuth.instance.currentUser;

      if (refreshed?.emailVerified == true) {
        _timer?.cancel();

        // Build safe fallback data if we don't have pending (e.g. app relaunch)
        final pending = widget.pending ??
            PendingUserData(
              email: refreshed?.email ?? '',
              displayName: refreshed?.displayName ?? '',
              firstName: '',
              surname: '',
              phoneNumber: '',
              languageCode: 'ru',
            );

        // Create Firestore user ONLY NOW (after verified)
        await _auth.createUserDocIfVerified(
          displayName: pending.displayName,
          firstName: pending.firstName,
          surname: pending.surname,
          phoneNumber: pending.phoneNumber,
          languageCode: (pending.languageCode == 'ky') ? 'ky' : 'ru',
        );

        _completed = true;

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainPage()),
              (_) => false,
        );
        return;
      }

      if (!silent && mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.notVerifiedYet)),
        );
      }
    } catch (_) {
      if (!silent && mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.unexpectedError)),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resendVerification() async {
    if (_sending) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final loc = AppLocalizations.of(context)!;
    setState(() => _sending = true);

    try {
      final lang = Localizations.localeOf(context).languageCode;
      await _auth.sendEmailVerification(
        actionCodeSettings: _emailActionCodeSettings(),
        languageCode: (lang == 'ky') ? 'ky' : (lang == 'ru') ? 'ru' : 'en',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.emailSent)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.unexpectedError)),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    const purple = Color(0xFF2A1A57);
    const bg = Color(0xFFF6F4FF);

    final email = FirebaseAuth.instance.currentUser?.email ??
        widget.pending?.email ??
        '';

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            loc.verifyEmailTitle,
            style: const TextStyle(color: purple, fontWeight: FontWeight.w800),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.verifyEmailSubtitle,
                style: TextStyle(
                  fontSize: 14.5,
                  color: Colors.black.withOpacity(0.70),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: purple,
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_checking || _sending)
                      ? null
                      : () => _checkEmailVerified(silent: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    disabledBackgroundColor: purple.withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _checking
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    loc.iVerifiedButton,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              TextButton(
                onPressed: (_checking || _sending) ? null : _resendVerification,
                child: Text(
                  loc.resendEmailButton,
                  style: const TextStyle(
                    color: purple,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const Spacer(),

              Text(
                loc.verifyEmailHint,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.black.withOpacity(0.60),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
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
  final String languageCode; // ru/ky

  PendingUserData({
    required this.email,
    required this.displayName,
    required this.firstName,
    required this.surname,
    required this.phoneNumber,
    required this.languageCode,
  });
}
