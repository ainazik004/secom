// ---------------- HOME PAGE ----------------

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secom/gen_l10n/app_localizations.dart';
import 'package:shimmer/shimmer.dart';

import 'categories/mathematics_page.dart';
import 'categories/analogy_page.dart';
import 'categories/reading_page.dart';
import 'categories/grammar_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<Map<String, dynamic>> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final snapshot =
    await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    return snapshot.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadUserData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const _HomeShimmer();
        return _HomeContent(data: snapshot.data!);
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  final Map<String, dynamic> data;

  const _HomeContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final fullName = (data['fullName'] ?? '') as String? ?? '';
    final greeting =
    fullName.isNotEmpty ? "${loc.hello}, $fullName!" : loc.hello;

    final categories = [
      _CategoryData(
        title: loc.math,
        subtitle: loc.over500questions,
        icon: Icons.calculate_rounded,
        accentColor: const Color(0xFFFF3D7F),
        page: const MathematicsPage(),
      ),
      _CategoryData(
        title: loc.analogy,
        subtitle: loc.sharpenReasoning,
        icon: Icons.compare_arrows_rounded,
        accentColor: const Color(0xFFFF8AB6),
        page: const AnalogyPage(),
      ),
      _CategoryData(
        title: loc.reading,
        subtitle: loc.over400passages,
        icon: Icons.menu_book_rounded,
        accentColor: const Color(0xFFB388FF),
        page: const ReadingPage(),
      ),
      _CategoryData(
        title: loc.grammar,
        subtitle: loc.over2000questions,
        icon: Icons.spellcheck_rounded,
        accentColor: const Color(0xFF2C015D),
        page: const GrammarPage(),
      ),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HERO BANNER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Container(
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
                    loc.welcomeToSecom,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.prepSmart,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Greeting
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.waving_hand_rounded,
                            color: Colors.white),
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
            ),
          ),

          // TITLE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              loc.homeCategories,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C015D),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // CATEGORY GRID
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 16) / 2;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: categories
                      .map((c) => SizedBox(
                    width: width,
                    child: _CategoryCard(data: c),
                  ))
                      .toList(),
                );
              },
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final _CategoryData data;

  const _CategoryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => data.page)),
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
              // Icon bubble
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: data.accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(data.icon, size: 28, color: data.accentColor),
              ),
              const SizedBox(height: 12),

              Text(
                data.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C015D),
                ),
              ),

              const SizedBox(height: 4),

              Expanded(
                child: Text(
                  data.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.55),
                    fontSize: 13,
                    height: 1.3,
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

class _CategoryData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Widget page;

  _CategoryData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.page,
  });
}

//
// ─────────────────────────────────────────────
//                SHIMMER PLACEHOLDERS
// ─────────────────────────────────────────────
//

class _HomeShimmer extends StatelessWidget {
  const _HomeShimmer();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // HERO shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Categories shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: List.generate(
                  4, (_) => const _CategoryShimmerCard()).toList(),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _CategoryShimmerCard extends StatelessWidget {
  const _CategoryShimmerCard();

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 56) / 2;

    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: 170,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
