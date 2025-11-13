import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secom/gen_l10n/app_localizations.dart';
import '../pages/login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<Map<String, dynamic>?> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.data();
  }

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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(loc.logout),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

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
        future: _loadUserData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final user = FirebaseAuth.instance.currentUser;

          final fullName = data['fullName'] ?? '';
          final email = data['email'] ?? user?.email ?? '';
          final phone = data['phone'] ?? '';
          final createdAt = data['createdAt']?.toDate();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 50,
                  backgroundColor: purple,
                  child: const Icon(Icons.person,
                      size: 60, color: Colors.white),
                ),

                const SizedBox(height: 16),

                Text(
                  fullName,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),

                Text(
                  email,
                  style: const TextStyle(
                      fontSize: 16, color: Colors.grey),
                ),

                const SizedBox(height: 20),

                // Profile info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.profileInfo,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Full Name
                      _infoRow(loc.fullName, fullName),
                      const Divider(),

                      // Email
                      _infoRow(loc.email, email),
                      const Divider(),

                      // Phone
                      _infoRow(loc.phone, phone),
                      const Divider(),

                      // Verified
                      _infoRow(
                        loc.verified,
                        user?.emailVerified == true
                            ? loc.verified
                            : loc.notVerified,
                      ),
                      const Divider(),

                      // Created At
                      if (createdAt != null)
                        _infoRow(
                          loc.createdAt,
                          "${createdAt.day}.${createdAt.month}.${createdAt.year}",
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Edit profile
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: Text(loc.editProfile),
                  ),
                ),

                const SizedBox(height: 12),

                // Change password
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (user != null && user.email != null) {
                        await FirebaseAuth.instance
                            .sendPasswordResetEmail(email: user.email!);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  "Password reset link sent to ${user.email}")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: Text(loc.changePassword),
                  ),
                ),

                const SizedBox(height: 12),

                // Logout
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _logout(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w500)),
          Text(value,
              style: const TextStyle(
                  fontSize: 16, color: Colors.black87)),
        ],
      ),
    );
  }
}
