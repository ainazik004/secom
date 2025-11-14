import 'package:flutter/material.dart';
import '../widgets/category_button.dart';
import 'profile_page.dart';
import 'notifications_page.dart';
import 'categories/mathematics_page.dart';
import 'categories/analogy_page.dart';
import 'categories/reading_page.dart';
import 'categories/grammar_page.dart';
import 'package:secom/gen_l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<Map<String, dynamic>> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    const purple = Color(0xFF2C015D);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Top bar with trophy icon
              FutureBuilder<Map<String, dynamic>>(
                future: _loadUserData(),
                builder: (context, snapshot) {
                  final data = snapshot.data ?? {};
                  final photoUrl = data["photoUrl"];
                  final trophies = data["trophies"] ?? 0;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/secom_logo.png',
                        height: 40,
                      ),

                      Row(
                        children: [
                          // Notifications
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_none,
                              color: Color(0xFF2C015D),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NotificationsPage(),
                                ),
                              );
                            },
                          ),

                          const SizedBox(width: 8),

                          // 🔥 TROPHY ICON + DYNAMIC NUMBER
                          FutureBuilder<Map<String, dynamic>>(
                            future: _loadUserData(),
                            builder: (context, snapshot) {
                              final data = snapshot.data ?? {};
                              final trophies = data["trophies"] ?? 0;

                              return Row(
                                children: [
                                  Icon(
                                    Icons.emoji_events,
                                    color: Colors.amber[600],
                                    size: 22,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    trophies.toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2C015D),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                              );
                            },
                          ),

                          // 🔥 PROFILE PICTURE (or default icon)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfilePage(),
                                ),
                              );
                            },
                            child: FutureBuilder<Map<String, dynamic>>(
                              future: _loadUserData(),
                              builder: (context, snapshot) {
                                final data = snapshot.data ?? {};
                                final photoUrl = data["photoUrl"];

                                return photoUrl == null
                                    ? const CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Color(0xFF2C015D),
                                  child: Icon(Icons.person, size: 18, color: Colors.white),
                                )
                                    : CircleAvatar(
                                  radius: 16,
                                  backgroundImage: NetworkImage(photoUrl),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // 🔹 Greeting text
              FutureBuilder<Map<String, dynamic>>(
                future: _loadUserData(),
                builder: (context, snapshot) {
                  final data = snapshot.data ?? {};
                  final name = data["fullName"] ?? "";

                  return Text(
                    name.isNotEmpty ? "${loc.hello}, $name!" : loc.hello,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // 🔹 Category buttons
              CategoryButton(title: loc.math, page: const MathematicsPage()),
              CategoryButton(title: loc.analogy, page: const AnalogyPage()),
              CategoryButton(title: loc.reading, page: const ReadingPage()),
              CategoryButton(title: loc.grammar, page: const GrammarPage()),
            ],
          ),
        ),
      ),
    );
  }
}
