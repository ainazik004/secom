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

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.data();
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

    // FIXED STORAGE PATH
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
  // Save Phone Number (Firestore)
  // ----------------------------------------------------------
  Future<void> _savePhone() async {
    final loc = AppLocalizations.of(context)!;
    final phone = _phoneCtrl.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (phone.isEmpty) return;

    setState(() => _savingPhone = true);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
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
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text("Invalid code.")));
              }
            },
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
    final loc = AppLocalizations.of(context)!;
    final purple = const Color(0xFF2C015D);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.profile),
        backgroundColor: purple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _loadUser(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!;
          final user = FirebaseAuth.instance.currentUser;

          final fullName = data["fullName"] ?? '';
          final email = data["email"] ?? user!.email!;
          final phone = data["phone"] ?? "";
          final phoneVerified = data["phoneVerified"] == true;
          final photoUrl = data["photoUrl"];
          final created = data["createdAt"]?.toDate();

          _phoneCtrl.text = phone;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // --------------------------------------------------
                // Profile Photo + Pencil Icon
                // --------------------------------------------------
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                      backgroundColor: purple,
                      child: photoUrl == null
                          ? const Icon(Icons.person, color: Colors.white, size: 60)
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
                            color: Colors.black.withOpacity(0.50),
                          ),
                          child: const Icon(Icons.edit,
                              size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(fullName,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),

                Text(email, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),

                // --------------------------------------------------
                // Info Card
                // --------------------------------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                          blurRadius: 6, offset: Offset(0, 2), color: Colors.black26)
                    ],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _info(loc.fullName, fullName),
                      const Divider(),

                      _info(loc.email, email),
                      const Divider(),

                      // PHONE FIELD
                      TextField(
                        controller: _phoneCtrl,
                        enabled: !phoneVerified,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: loc.phone,
                          suffixIcon: !phoneVerified
                              ? IconButton(
                            icon: _savingPhone
                                ? const CircularProgressIndicator()
                                : const Icon(Icons.save),
                            onPressed: _savePhone,
                          )
                              : null,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // VERIFY BUTTON
                      if (!phoneVerified)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _sendingCode
                                ? null
                                : () => _verifyPhoneNumber(_phoneCtrl.text.trim()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _sendingCode
                                ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                                : Text(loc.verifyPhone),
                          ),
                        ),

                      const Divider(),

                      if (created != null)
                        _info(
                          loc.createdAt,
                          "${created.day}.${created.month}.${created.year}",
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Change Password
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (email.isNotEmpty) {
                        await FirebaseAuth.instance
                            .sendPasswordResetEmail(email: email);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(loc.resetEmailSent)));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(loc.changePassword),
                  ),
                ),

                const SizedBox(height: 12),

                // LOGOUT
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _logout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(loc.logout),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _info(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
