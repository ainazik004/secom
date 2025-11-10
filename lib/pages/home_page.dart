import 'package:flutter/material.dart';
import '../widgets/category_button.dart';
import 'profile_page.dart';
import 'notifications_page.dart';
import 'categories/mathematics_page.dart';
import 'categories/analogy_page.dart';
import 'categories/reading_page.dart';
import 'categories/grammar_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          child:
                          Icon(Icons.person, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Привет, Бекзат!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              const CategoryButton(
                title: 'МАТЕМАТИКА',
                page: MathematicsPage(),
              ),
              const CategoryButton(
                title: 'АНАЛОГИЯ И ДОПОЛНЕНИЕ',
                page: AnalogyPage(),
              ),
              const CategoryButton(
                title: 'ЧТЕНИЕ И ПОНИМАНИЕ',
                page: ReadingPage(),
              ),
              const CategoryButton(
                title: 'ПРАКТИЧЕСКАЯ ГРАММАТИКА РУССКОГО ЯЗЫКА',
                page: GrammarPage(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
