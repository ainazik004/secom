import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secom/gen_l10n/app_localizations.dart';

import 'categories/mathematics_page.dart';
import 'categories/analogy_page.dart';
import 'categories/reading_page.dart';
import 'categories/grammar_page.dart';

class HomePage extends StatelessWidget {
  final bool embedded;
  final Map<String, dynamic>? userData;

  const HomePage({
    super.key,
    this.embedded = false,
    this.userData,
  });

  Future<Map<String, dynamic>> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return snapshot.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    if (embedded && userData != null) {
      return _HomeContent(data: userData!);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FF),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _loadUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final data = snapshot.data ?? {};
            return _HomeContent(data: data);
          },
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final Map<String, dynamic> data;

  const _HomeContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final name = (data['fullName'] ?? '') as String? ?? '';
    final greeting = name.isNotEmpty ? '${loc.hello}, $name!' : loc.hello;

    final categories = <_CategoryData>[
      _CategoryData(
        title: loc.math,
        subtitle: '500+ Questions',
        icon: Icons.calculate_rounded,
        accentColor: const Color(0xFFFF3D7F),
        page: const MathematicsPage(),
      ),
      _CategoryData(
        title: loc.analogy,
        subtitle: 'Sharpen reasoning skills',
        icon: Icons.compare_arrows_rounded,
        accentColor: const Color(0xFFFF8AB6),
        page: const AnalogyPage(),
      ),
      _CategoryData(
        title: loc.reading,
        subtitle: '400+ Passages',
        icon: Icons.menu_book_rounded,
        accentColor: const Color(0xFFB388FF),
        page: const ReadingPage(),
      ),
      _CategoryData(
        title: loc.reading,
        subtitle: 'Timed practice sets',
        icon: Icons.auto_stories_rounded,
        accentColor: const Color(0xFF8C6CFF),
        page: const ReadingPage(),
      ),
      _CategoryData(
        title: loc.grammar,
        subtitle: '2000+ Questions',
        icon: Icons.spellcheck_rounded,
        accentColor: const Color(0xFF2C015D),
        page: const GrammarPage(),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroCard(greeting: greeting),
          const SizedBox(height: 28),
          Text(
            loc.homeCategories,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2C015D).withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final itemWidth = (width - 16) / 2;
              final firstGroup = categories.take(4).toList();
              final trailing = categories.skip(4).toList();

              return Column(
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: firstGroup
                        .map(
                          (item) => SizedBox(
                            width: itemWidth,
                            child: _CategoryCard(data: item),
                          ),
                        )
                        .toList(),
                  ),
                  for (final item in trailing) ...[
                    const SizedBox(height: 18),
                    _CategoryCard(data: item, isWide: true),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String greeting;

  const _HeroCard({required this.greeting});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7FB2), Color(0xFF7F4BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A2C015D),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to SECOM Prep',
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Prep smart, enjoy learning, reach your goals.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.waving_hand_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  greeting,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final _CategoryData data;
  final bool isWide;

  const _CategoryCard({required this.data, this.isWide = false});

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return _WideCategoryCard(data: data);
    }

    return _TileCategoryCard(data: data);
  }
}

class _TileCategoryCard extends StatelessWidget {
  final _CategoryData data;

  const _TileCategoryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => data.page),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: data.accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  data.icon,
                  color: data.accentColor,
                  size: 28,
                ),
              ),
              const Spacer(),
              Text(
                data.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C015D),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                data.subtitle,
                style: TextStyle(
                  color: Colors.black.withOpacity(0.55),
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: data.accentColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WideCategoryCard extends StatelessWidget {
  final _CategoryData data;

  const _WideCategoryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => data.page),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x142C015D),
                blurRadius: 16,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: data.accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  data.icon,
                  color: data.accentColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C015D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.subtitle,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.55),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: data.accentColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Widget page;

  const _CategoryData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.page,
  });
}
