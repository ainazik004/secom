import 'package:flutter/material.dart';
import '../widgets/category_button.dart';
import 'profile_page.dart';
import 'notifications_page.dart';
import 'categories/mathematics_page.dart';
import 'categories/analogy_page.dart';
import 'categories/reading_page.dart';
import 'categories/grammar_page.dart';
import 'package:secom/gen_l10n/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Access localized strings
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Top bar (logo + icons)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/secom_logo.png',
                    height: 40,
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none,
                            color: Color(0xFF2C015D)),
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
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfilePage(),
                            ),
                          );
                        },
                        child: const CircleAvatar(
                          radius: 14,
                          backgroundColor: Color(0xFF2C015D),
                          child: Icon(Icons.person,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 🔹 Localized greeting
              Text(
                // Example: "Hello, Bekzat!" (you can make this localized too)
                '${loc.hello}, Бекзат!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              // 🔹 Localized category buttons (❌ remove const)
              CategoryButton(
                title: loc.math,
                page: const MathematicsPage(),
              ),
              CategoryButton(
                title: loc.analogy,
                page: const AnalogyPage(),
              ),
              CategoryButton(
                title: loc.reading,
                page: const ReadingPage(),
              ),
              CategoryButton(
                title: loc.grammar,
                page: const GrammarPage(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
