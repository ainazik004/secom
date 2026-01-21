import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:zhalbyrak/gen_l10n/app_localizations.dart';
import '../pages/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _purple = Color(0xFF2C015D);
  static const _bg = Color(0xFFF6F4FF);

  bool _uploading = false;
  bool _removingPhoto = false;
  bool _savingPhone = false;
  bool _sendingCode = false;

  final _phoneCtrl = TextEditingController();
  bool _phoneInitialized = false;

  Future<DocumentSnapshot<Map<String, dynamic>>?> _loadUserDoc() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ---------- Helpers ----------
  String _asString(dynamic v) => (v is String) ? v.trim() : '';

  String _resolveDisplayName(Map<String, dynamic> data, User? authUser) {
    // Prefer Firestore fields (most reliable)
    final displayName = _asString(data['displayName']);
    if (displayName.isNotEmpty) return displayName;

    final fullName = _asString(data['fullName']);
    if (fullName.isNotEmpty) return fullName;

    final firstName = _asString(data['firstName']);
    final surname = _asString(data['surname']);
    final combined = ('$firstName $surname').trim();
    if (combined.isNotEmpty) return combined;

    // Fallback: Firebase Auth displayName
    final authName = (authUser?.displayName ?? '').trim();
    if (authName.isNotEmpty) return authName;

    return '—';
  }

  String? _resolvePhotoUrl(Map<String, dynamic> data, User? authUser) {
    final fs = _asString(data['photoUrl']);
    if (fs.isNotEmpty) return fs;
    final auth = (authUser?.photoURL ?? '').trim();
    return auth.isNotEmpty ? auth : null;
  }

  DateTime? _resolveCreatedAt(Map<String, dynamic> data) {
    final v = data['createdAt'];
    if (v is Timestamp) return v.toDate();
    return null;
  }

  // ----------------------------------------------------------
  // Upload Profile Photo (allowed only after phone verified)
  // ----------------------------------------------------------
  Future<void> _uploadProfilePhoto() async {
    final loc = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();

    setState(() => _uploading = true);

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child("users")
          .child(user.uid)
          .child("profile.jpg");

      await ref.putData(bytes);
      final url = await ref.getDownloadURL();

      // Update Firestore first
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        "photoUrl": url,
      }, SetOptions(merge: true));

      // Optional: also update Auth photoURL (best effort)
      try {
        await user.updatePhotoURL(url);
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.photoUpdated)));
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.unexpectedError)),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ----------------------------------------------------------
  // Remove Profile Photo (allowed only after phone verified)
  // ----------------------------------------------------------
  Future<void> _removeProfilePhoto() async {
    final loc = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _removingPhoto = true);

    try {
      // Remove from Storage (ignore if missing)
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child("users")
            .child(user.uid)
            .child("profile.jpg");
        await ref.delete();
      } catch (_) {}

      // Remove in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        "photoUrl": FieldValue.delete(),
      }, SetOptions(merge: true));

      // Optional: clear Auth photoURL (best effort)
      try {
        await user.updatePhotoURL(null);
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.photoUpdated)));
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.unexpectedError)),
      );
    } finally {
      if (mounted) setState(() => _removingPhoto = false);
    }
  }

  // ----------------------------------------------------------
  // Save Phone (Firestore)
  // ----------------------------------------------------------
  Future<void> _savePhone() async {
    final loc = AppLocalizations.of(context)!;
    final phone = _phoneCtrl.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (phone.isEmpty) return;

    setState(() => _savingPhone = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        "phone": phone,
        "phoneNumber": phone, // keep both (compat with older code)
        "phoneVerified": false,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.phoneUpdated)));
      setState(() {});
    } finally {
      if (mounted) setState(() => _savingPhone = false);
    }
  }

  // ----------------------------------------------------------
  // Verify Phone Number (SMS)
  // ----------------------------------------------------------
  Future<void> _verifyPhoneNumber(String phone) async {
    final loc = AppLocalizations.of(context)!;

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.enterPhone)));
      return;
    }

    setState(() => _sendingCode = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (cred) async {
        try {
          await FirebaseAuth.instance.currentUser?.updatePhoneNumber(cred);
        } catch (_) {}

        await _markPhoneVerified();

        if (!mounted) return;
        setState(() => _sendingCode = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.phoneVerified)));
      },
      verificationFailed: (e) {
        if (!mounted) return;
        setState(() => _sendingCode = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.message ?? e.code}")),
        );
      },
      codeSent: (id, _) {
        if (!mounted) return;
        setState(() => _sendingCode = false);
        _showSmsDialog(id);
      },
      codeAutoRetrievalTimeout: (_) {
        if (!mounted) return;
        setState(() => _sendingCode = false);
      },
    );
  }

  Future<void> _markPhoneVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      "phoneVerified": true,
    }, SetOptions(merge: true));

    if (mounted) setState(() {});
  }

  void _showSmsDialog(String verificationId) {
    final loc = AppLocalizations.of(context)!;
    final smsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.smsCode),
        content: TextField(
          controller: smsCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: loc.smsCode),
        ),
        actions: [
          TextButton(
            child: Text(loc.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final cred = PhoneAuthProvider.credential(
                  verificationId: verificationId,
                  smsCode: smsCtrl.text.trim(),
                );

                await FirebaseAuth.instance.currentUser?.updatePhoneNumber(cred);

                await _markPhoneVerified();

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(loc.phoneVerified)));
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.invalidCode)),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
            ),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Logout
  // ----------------------------------------------------------
  Future<void> _logout(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.confirmation),
        content: Text(loc.logoutQuestion),
        actions: [
          TextButton(
            child: Text(loc.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                    (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
            ),
            child: Text(loc.logout),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // UI
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
          future: _loadUserDoc(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final doc = snap.data;
            final data = doc?.data() ?? <String, dynamic>{};
            final user = FirebaseAuth.instance.currentUser;

            final name = _resolveDisplayName(data, user);
            final email = _asString(data["email"]).isNotEmpty
                ? _asString(data["email"])
                : (user?.email ?? '');

            final phone = _asString(data["phone"]).isNotEmpty
                ? _asString(data["phone"])
                : _asString(data["phoneNumber"]);

            final phoneVerified = data["phoneVerified"] == true;
            final photoUrl = _resolvePhotoUrl(data, user);
            final created = _resolveCreatedAt(data);

            // Initialize phone field once (do NOT assign every build)
            if (!_phoneInitialized) {
              _phoneCtrl.text = phone;
              _phoneInitialized = true;
            }

            return Column(
              children: [
                // Top bar
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  child: Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          loc.settings, // or loc.profile if you have it
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _purple,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Header card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x142C015D),
                                blurRadius: 16,
                                offset: Offset(0, 10),
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0x112C015D),
                            ),
                          ),
                          child: Row(
                            children: [
                              _ProfileAvatar(
                                radius: 38,
                                photoUrl: photoUrl,
                                name: name,
                                enabled: phoneVerified,
                                uploading: _uploading || _removingPhoto,
                                onEdit: phoneVerified ? _uploadProfilePhoto : null,
                                onRemove: (phoneVerified && (photoUrl != null))
                                    ? _removeProfilePhoto
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: _purple,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.black.withOpacity(0.55),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _ChipStatus(
                                      ok: phoneVerified,
                                      text: phoneVerified
                                          ? loc.phoneVerified
                                          : loc.notVerified,
                                    ),
                                    if (!phoneVerified) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        loc.verifyPhone, // “Verify phone”
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: Colors.black.withOpacity(0.55),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (!phoneVerified) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x142C015D),
                                  blurRadius: 16,
                                  offset: Offset(0, 10),
                                ),
                              ],
                              border: Border.all(
                                color: const Color(0x112C015D),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.phone,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: _purple,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _phoneCtrl,
                                  enabled: !_savingPhone,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    hintText: loc.phoneHint996,
                                    filled: true,
                                    fillColor: const Color(0xFFF3F1FA),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0x332C015D),
                                        width: 1.2,
                                      ),
                                    ),
                                  ),
                                  onEditingComplete: _savePhone,
                                  onSubmitted: (_) => _savePhone(),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: (_savingPhone || _sendingCode)
                                            ? null
                                            : () async {
                                          await _savePhone();
                                          await _verifyPhoneNumber(
                                            _phoneCtrl.text.trim(),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _purple,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor:
                                          _purple.withOpacity(0.5),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(16),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: (_savingPhone || _sendingCode)
                                            ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child:
                                          CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            color: Colors.white,
                                          ),
                                        )
                                            : Text(
                                          loc.verifyPhone,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  loc.verifyEmailHint, // reuse a hint text if needed
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black.withOpacity(0.55),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Info card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x142C015D),
                                blurRadius: 16,
                                offset: Offset(0, 10),
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0x112C015D),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.profileInfo,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _purple,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _infoRow(loc.fullName, name),
                              const Divider(height: 22),
                              _infoRow(loc.email, email),
                              const Divider(height: 22),
                              _infoRow(
                                loc.phone,
                                phone.isEmpty ? "—" : phone,
                              ),
                              if (created != null) ...[
                                const Divider(height: 22),
                                _infoRow(
                                  loc.createdAt,
                                  "${created.day.toString().padLeft(2, '0')}.${created.month.toString().padLeft(2, '0')}.${created.year}",
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Change password
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: email.isEmpty
                                ? null
                                : () async {
                              await FirebaseAuth.instance
                                  .sendPasswordResetEmail(email: email);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(loc.resetEmailSent)),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _purple,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                              _purple.withOpacity(0.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              loc.changePassword,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Logout
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _logout(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Colors.red,
                                width: 1.4,
                              ),
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              loc.logout,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: _purple.withOpacity(0.80),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14.5,
              color: Colors.black.withOpacity(0.78),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------- Small UI widgets ----------

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A2C015D),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: _ProfilePageState._purple, size: 20),
      ),
    );
  }
}

class _ChipStatus extends StatelessWidget {
  final bool ok;
  final String text;

  const _ChipStatus({required this.ok, required this.text});

  @override
  Widget build(BuildContext context) {
    final bg = ok ? const Color(0xFFE9F7EF) : const Color(0xFFFFF3E0);
    final fg = ok ? const Color(0xFF1E7E34) : const Color(0xFFB26A00);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ok ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: fg, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final double radius;
  final String? photoUrl;
  final String name;

  final bool enabled;
  final bool uploading;

  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  const _ProfileAvatar({
    required this.radius,
    required this.photoUrl,
    required this.name,
    required this.enabled,
    required this.uploading,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = (photoUrl != null && photoUrl!.trim().isNotEmpty);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: _ProfilePageState._purple,
          backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
          child: !hasPhoto
              ? Text(
            name.isNotEmpty ? name[0].toUpperCase() : "?",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: radius * 0.70,
            ),
          )
              : null,
        ),

        // If not verified: show lock overlay
        if (!enabled)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.35),
              ),
              child: const Icon(Icons.lock_rounded, color: Colors.white),
            ),
          ),

        // Edit button
        Positioned(
          bottom: -2,
          right: -2,
          child: _MiniActionButton(
            icon: uploading ? null : Icons.edit_rounded,
            loading: uploading,
            enabled: enabled && !uploading,
            onTap: onEdit,
          ),
        ),

        // Remove button (only if has photo)
        if (hasPhoto)
          Positioned(
            bottom: -2,
            left: -2,
            child: _MiniActionButton(
              icon: uploading ? null : Icons.delete_outline_rounded,
              loading: false,
              enabled: enabled && !uploading,
              onTap: onRemove,
            ),
          ),
      ],
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  final IconData? icon;
  final bool loading;
  final bool enabled;
  final VoidCallback? onTap;

  const _MiniActionButton({
    required this.icon,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = enabled ? Colors.black.withOpacity(0.55) : Colors.black.withOpacity(0.25);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
        ),
        child: Center(
          child: loading
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}
