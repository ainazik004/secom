import 'package:flutter/material.dart';
import 'package:secom/gen_l10n/app_localizations.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    const purple = Color(0xFF2C015D);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TOP GRADIENT SECTION
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFF9D7B),
                      Color(0xFF7D73FF),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      // add a localized key if you wish, e.g. loc.completionRate
                      'Completion Rate',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your completion progress across skills',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Simple placeholder "radar" card (no external libs)
                    SizedBox(
                      height: 220,
                      child: Center(
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '1 %',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // PROGRESS DETAIL TITLE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress Detail',
                      style: TextStyle(
                        color: purple,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Track your performance for each section.',
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // GRID OF SKILL CARDS (mock values for now)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: const [
                    _SkillCard(
                      icon: Icons.calculate_rounded,
                      titleKey: 'Math',
                      answered: 0,
                      total: 500,
                      percent: 0,
                    ),
                    _SkillCard(
                      icon: Icons.compare_arrows_rounded,
                      titleKey: 'Analogy',
                      answered: 0,
                      total: 300,
                      percent: 0,
                    ),
                    _SkillCard(
                      icon: Icons.menu_book_rounded,
                      titleKey: 'Reading',
                      answered: 9,
                      total: 489,
                      percent: 1,
                    ),
                    _SkillCard(
                      icon: Icons.spellcheck_rounded,
                      titleKey: 'Grammar',
                      answered: 0,
                      total: 600,
                      percent: 0,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  final IconData icon;
  final String titleKey;
  final int answered;
  final int total;
  final int percent;

  const _SkillCard({
    required this.icon,
    required this.titleKey,
    required this.answered,
    required this.total,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 20 * 2 - 16) / 2;

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x142C015D),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF4ECFF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                size: 26,
                color: const Color(0xFF2C015D),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              titleKey,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C015D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$answered / $total answered',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '$percent%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'correct',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
