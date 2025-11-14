import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:secom/gen_l10n/app_localizations.dart';
import '../pages/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _uploading = false;
  bool _savingPhone = false;
  bool _sendingCode = false;

  final _phoneCtrl = TextEditingController();

  Future<Map<String, dynamic>?> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc =
    await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    return doc.data();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // Upload Profile Photo
  // ----------------------------------------------------------
  Future<void> _uploadProfilePhoto() async {
    final loc = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    Uint8List bytes = await file.readAsBytes();

    setState(() => _uploading = true);

    final ref = FirebaseStorage.instance
        .ref()
        .child("users")
        .child(user.uid)
        .child("profile.jpg");

    await ref.putData(bytes);
    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({"photoUrl": url});

    setState(() => _uploading = false);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(loc.photoUpdated)));
  }

  // ----------------------------------------------------------
  // Save Phone Number (Firestore) – called automatically
  // ----------------------------------------------------------
  Future<void> _savePhone() async {
    final loc = AppLocalizations.of(context)!;
    final phone = _phoneCtrl.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (phone.isEmpty) return;

    setState(() => _savingPhone = true);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      "phone": phone,
      "phoneVerified": false,
    });

    setState(() => _savingPhone = false);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(loc.phoneUpdated)));
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
        await FirebaseAuth.instance.currentUser!.updatePhoneNumber(cred);
        setState(() => _sendingCode = false);

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.phoneVerified)));

        _markPhoneVerified();
      },
      verificationFailed: (e) {
        setState(() => _sendingCode = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
      },
      codeSent: (id, _) {
        setState(() => _sendingCode = false);
        _showSmsDialog(id);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> _markPhoneVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({"phoneVerified": true});

    setState(() {});
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

                await FirebaseAuth.instance.currentUser!
                    .updatePhoneNumber(cred);

                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(loc.phoneVerified)));

                _markPhoneVerified();
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.invalidCode)),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C015D),
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
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                    (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C015D),
            ),
            child: Text(loc.logout),
          )
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // UI
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final purple = const Color(0xFF2C015D);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FF),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _loadUser(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snap.hasData || snap.data == null) {
              return const Center(child: SizedBox());
            }

            final data = snap.data!;
            final user = FirebaseAuth.instance.currentUser;
            final fullName = data["fullName"] ?? '';
            final email = data["email"] ?? user?.email ?? '';
            final phone = data["phone"] ?? "";
            final phoneVerified = data["phoneVerified"] == true;
            final photoUrl = data["photoUrl"];
            final created = data["createdAt"]?.toDate();

            _phoneCtrl.text = phone;

            return Column(
              children: [
                // Top row with circular X
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A2C015D),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF2C015D),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar + name + email
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 55,
                              backgroundImage: photoUrl != null
                                  ? NetworkImage(photoUrl)
                                  : null,
                              backgroundColor: purple,
                              child: photoUrl == null
                                  ? const Icon(Icons.person,
                                  color: Colors.white, size: 60)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _uploadProfilePhoto,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                  child: _uploading
                                      ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                      : const Icon(Icons.edit,
                                      size: 18, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C015D),
                          ),
                        ),
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Info card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x142C015D),
                                blurRadius: 16,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.profileInfo,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2C015D),
                                ),
                              ),
                              const SizedBox(height: 12),

                              _infoRow(loc.fullName, fullName),
                              const Divider(height: 24),

                              _infoRow(loc.email, email),
                              const Divider(height: 24),

                              // Phone field
                              TextField(
                                controller: _phoneCtrl,
                                enabled: !phoneVerified && !_savingPhone,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: loc.phone,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onEditingComplete: _savePhone,
                                onSubmitted: (_) => _savePhone(),
                              ),
                              const SizedBox(height: 12),

                              // Phone verify status + button
                              Row(
                                children: [
                                  Icon(
                                    phoneVerified
                                        ? Icons.check_circle_rounded
                                        : Icons.info_outline_rounded,
                                    color: phoneVerified
                                        ? Colors.green
                                        : Colors.orangeAccent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    phoneVerified
                                        ? loc.phoneVerified
                                        : loc.notVerified,
                                    style: TextStyle(
                                      color: phoneVerified
                                          ? Colors.green
                                          : Colors.orangeAccent,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              if (!phoneVerified)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _sendingCode
                                        ? null
                                        : () => _verifyPhoneNumber(
                                        _phoneCtrl.text.trim()),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: purple,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _sendingCode
                                        ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                        : Text(loc.verifyPhone),
                                  ),
                                ),

                              const SizedBox(height: 12),
                              if (created != null)
                                _infoRow(
                                  loc.createdAt,
                                  "${created.day}.${created.month}.${created.year}",
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Change password button (purple)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (email.isNotEmpty) {
                                await FirebaseAuth.instance
                                    .sendPasswordResetEmail(email: email);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(loc.resetEmailSent),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: purple,
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(loc.changePassword),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Logout button – transparent with red outline
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
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: Colors.transparent,
                            ),
                            child: Text(
                              loc.logout,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Color(0xFF2C015D),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }
}
