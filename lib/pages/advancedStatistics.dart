import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';

class AdvancedStatisticsPage extends StatelessWidget {
  const AdvancedStatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F4FF),
        body: SafeArea(
          child: Center(
            child: Text(
              loc.notLoggedIn,
              style: TextStyle(
                color: Colors.black.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FF),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, snapshot) {
            final header = _AdvancedStatsHeader(
              title: loc.advancedStatisticsTitle,
              subtitle: loc.statsSubtitle,
            );

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  header,
                  const Expanded(child: Center(child: CircularProgressIndicator())),
                ],
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Column(
                children: [
                  header,
                  Expanded(
                    child: Center(
                      child: Text(
                        loc.noStatisticsYet,
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            final data = snapshot.data!.data() ?? <String, dynamic>{};

            // ───────────────────────── helpers ─────────────────────────
            num _num(String key, [num fallback = 0]) {
              final v = data[key];
              return v is num ? v : fallback;
            }

            Map<String, dynamic> _map(dynamic v) {
              if (v is Map<String, dynamic>) return v;
              if (v is Map) return Map<String, dynamic>.from(v);
              return <String, dynamic>{};
            }

            int _asInt(dynamic v, {int fallback = 0}) {
              if (v == null) return fallback;
              if (v is int) return v;
              if (v is num) return v.toInt();
              if (v is String) return int.tryParse(v) ?? fallback;
              return fallback;
            }

            double _asDouble(dynamic v, {double fallback = 0.0}) {
              if (v == null) return fallback;
              if (v is double) return v;
              if (v is num) return v.toDouble();
              if (v is String) return double.tryParse(v) ?? fallback;
              return fallback;
            }

            // ───────────────────────── global stats ─────────────────────────
            final totalAnswered = _num('totalQuestionsAnswered').toInt().clamp(0, 1 << 31);
            final totalCorrect = _num('totalCorrectAnswers').toInt().clamp(0, totalAnswered);

            final accuracy =
            totalAnswered == 0 ? 0.0 : (totalCorrect / totalAnswered).clamp(0.0, 1.0);

            final avgScorePercent = _num('averageScore').toDouble().clamp(0.0, 100.0);

            final avgTimePerQuestionSeconds =
            _num('averageTimePerQuestionSeconds').toDouble().clamp(0.0, 3600.0);

            final totalStudySeconds = _num('totalStudyTimeSeconds').toInt().clamp(0, 1 << 31);

            final currentStreakDays = _num('currentStreakDays').toInt().clamp(0, 36500);
            final longestStreakDays = _num('longestStreakDays').toInt().clamp(0, 36500);

            final trophies = _num('trophies').toInt().clamp(0, 1 << 31);
            final totalTestsCompleted = _num('totalTestsCompleted').toInt().clamp(0, 1 << 31);

            // ───────────────────────── category stats ─────────────────────────
            final categoryStats = _map(data['categoryStats']);

            Map<String, dynamic> _cat(String key) => _map(categoryStats[key]);

            int _catAnswered(String key) => _asInt(_cat(key)['answered']);
            int _catCorrect(String key) => _asInt(_cat(key)['correct']);
            int _catTests(String key) => _asInt(_cat(key)['testsCompleted']);
            double _catAvgScore(String key) => _asDouble(_cat(key)['avgScore']).clamp(0.0, 100.0);

            double _catAccuracy(String key) {
              final a = _catAnswered(key);
              if (a <= 0) return 0.0;
              final c = _catCorrect(key).clamp(0, a);
              return (c / a).clamp(0.0, 1.0);
            }

            final categories = <_CategoryStat>[
              _CategoryStat(
                key: 'math',
                title: loc.math,
                icon: Icons.calculate_rounded,
                iconColor: const Color(0xFF3B82F6),
                answered: _catAnswered('math'),
                correct: _catCorrect('math'),
                avgScorePercent: _catAvgScore('math'),
                testsCompleted: _catTests('math'),
                accuracy: _catAccuracy('math'),
              ),
              _CategoryStat(
                key: 'reading',
                title: loc.reading,
                icon: Icons.menu_book_rounded,
                iconColor: const Color(0xFF22C55E),
                answered: _catAnswered('reading'),
                correct: _catCorrect('reading'),
                avgScorePercent: _catAvgScore('reading'),
                testsCompleted: _catTests('reading'),
                accuracy: _catAccuracy('reading'),
              ),
              _CategoryStat(
                key: 'analogy',
                title: loc.analogy,
                icon: Icons.compare_arrows_rounded,
                iconColor: const Color(0xFFF59E0B),
                answered: _catAnswered('analogy'),
                correct: _catCorrect('analogy'),
                avgScorePercent: _catAvgScore('analogy'),
                testsCompleted: _catTests('analogy'),
                accuracy: _catAccuracy('analogy'),
              ),
              _CategoryStat(
                key: 'grammar',
                title: loc.grammar,
                icon: Icons.spellcheck_rounded,
                iconColor: const Color(0xFFA855F7),
                answered: _catAnswered('grammar'),
                correct: _catCorrect('grammar'),
                avgScorePercent: _catAvgScore('grammar'),
                testsCompleted: _catTests('grammar'),
                accuracy: _catAccuracy('grammar'),
              ),
            ];

            // ───────────────────────── recentResults: r0..r6 (0..100), oldest->newest ─────────────────────────
            final recentResultsMap = _map(data['recentResults']);
            final List<double> recentAccPct = [];
            for (int i = 0; i < 50; i++) {
              final k = 'r$i';
              if (!recentResultsMap.containsKey(k)) break;
              recentAccPct.add(_asDouble(recentResultsMap[k]).clamp(0.0, 100.0));
            }

            if (recentAccPct.isEmpty) {
              recentAccPct.addAll(List<double>.filled(7, avgScorePercent));
            }
            if (recentAccPct.length > 7) {
              final tail = recentAccPct.sublist(recentAccPct.length - 7);
              recentAccPct
                ..clear()
                ..addAll(tail);
            }

            // ───────────────────────── formatting ─────────────────────────
            String _fmtTotalStudy(int seconds) {
              final totalMinutes = seconds ~/ 60;
              final h = totalMinutes ~/ 60;
              final m = totalMinutes % 60;
              if (h <= 0) return "${m} ${loc.minutes}";
              return "${h} ${loc.hours} ${m} ${loc.minutes}";
            }

            String _fmtSeconds(double s) => "${s.round()} ${loc.seconds}";

            // ───────────────────────── layout ─────────────────────────
            return LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    header,
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle(label: loc.overview),
                              const SizedBox(height: 8),
                              _OverviewCard(
                                loc: loc,
                                accuracy: accuracy,
                                totalAnswered: totalAnswered,
                                totalCorrect: totalCorrect,
                                avgScorePercent: avgScorePercent,
                                avgTimePerQuestionLabel: _fmtSeconds(avgTimePerQuestionSeconds),
                              ),
                              const SizedBox(height: 14),
                              _HighlightsCard(
                                loc: loc,
                                trophies: trophies,
                                totalTestsCompleted: totalTestsCompleted,
                                currentStreakDays: currentStreakDays,
                                longestStreakDays: longestStreakDays,
                                totalStudyLabel: _fmtTotalStudy(totalStudySeconds),
                              ),
                              const SizedBox(height: 22),
                              _SectionTitle(label: loc.categoryBreakdown),
                              const SizedBox(height: 8),
                              _CategoryCardsGrid(loc: loc, categories: categories),
                              const SizedBox(height: 20),
                              _CategoryBarsCard(loc: loc, categories: categories),
                              const SizedBox(height: 20),
                              _SectionTitle(label: loc.recentTestPerformance),
                              const SizedBox(height: 8),
                              _RecentResultsCard(loc: loc, recentAccPct: recentAccPct),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────
class _AdvancedStatsHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _AdvancedStatsHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 18, bottom: 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF7FB2), Color(0xFF7F4BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Section title
// ─────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF2C015D),
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Card shell
// ─────────────────────────────────────────────────────────────
class _CardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _CardShell({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
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
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Overview card
// ─────────────────────────────────────────────────────────────
class _OverviewCard extends StatelessWidget {
  final AppLocalizations loc;
  final double accuracy;
  final int totalAnswered;
  final int totalCorrect;
  final double avgScorePercent;
  final String avgTimePerQuestionLabel;

  const _OverviewCard({
    required this.loc,
    required this.accuracy,
    required this.totalAnswered,
    required this.totalCorrect,
    required this.avgScorePercent,
    required this.avgTimePerQuestionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: accuracy.clamp(0.0, 1.0),
                  strokeWidth: 7,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7F4BFF)),
                ),
                Text(
                  "${(accuracy * 100).round()}%",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2C015D),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.overallAccuracy,
                  style: const TextStyle(
                    color: Color(0xFF2C015D),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _MiniStat(label: loc.answered, value: "$totalAnswered"),
                    const SizedBox(width: 14),
                    _MiniStat(label: loc.correct, value: "$totalCorrect"),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _MiniStat(label: loc.avgScore, value: "${avgScorePercent.round()}%"),
                    const SizedBox(width: 14),
                    _MiniStat(label: loc.avgTimePerQuestion, value: avgTimePerQuestionLabel),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2C015D),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Highlights card (colorful icons + clock for study time)
// ─────────────────────────────────────────────────────────────
class _HighlightsCard extends StatelessWidget {
  final AppLocalizations loc;
  final int trophies;
  final int totalTestsCompleted;
  final int currentStreakDays;
  final int longestStreakDays;
  final String totalStudyLabel;

  const _HighlightsCard({
    required this.loc,
    required this.trophies,
    required this.totalTestsCompleted,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.totalStudyLabel,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        children: [
          _RowStat(
            icon: Icons.emoji_events_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: loc.trophies,
            value: "$trophies",
          ),
          const SizedBox(height: 10),
          _RowStat(
            icon: Icons.fact_check_rounded,
            iconColor: const Color(0xFF3B82F6),
            title: loc.testsCompleted,
            value: "$totalTestsCompleted",
          ),
          const SizedBox(height: 10),
          _RowStat(
            icon: Icons.access_time_rounded,
            iconColor: const Color(0xFF06B6D4),
            title: loc.studyTime,
            value: totalStudyLabel,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _RowStat(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFEF4444),
                  title: loc.currentStreak,
                  value: "$currentStreakDays ${loc.days}",
                  compact: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RowStat(
                  icon: Icons.whatshot_rounded,
                  iconColor: const Color(0xFF22C55E),
                  title: loc.longestStreak,
                  value: "$longestStreakDays ${loc.days}",
                  compact: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RowStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final bool compact;

  const _RowStat({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: const Color(0xFF2C015D),
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: TextStyle(
            color: Colors.black.withOpacity(0.7),
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Category cards grid (adaptive: 1 column on narrow phones)
// ─────────────────────────────────────────────────────────────
class _CategoryCardsGrid extends StatelessWidget {
  final AppLocalizations loc;
  final List<_CategoryStat> categories;

  const _CategoryCardsGrid({required this.loc, required this.categories});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final columns = w < 380 ? 1 : 2;
        final itemW = columns == 1 ? w : (w - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: categories.map((cat) {
            return SizedBox(
              width: itemW,
              child: _CardShell(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(cat.icon, color: cat.iconColor),
                    const SizedBox(height: 10),
                    Text(
                      cat.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF2C015D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${loc.correct}: ${cat.correct}",
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.65),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${loc.answered}: ${cat.answered}",
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.65),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: cat.accuracy.clamp(0.0, 1.0),
                        minHeight: 7,
                        backgroundColor: const Color(0xFFECE7FF),
                        valueColor: AlwaysStoppedAnimation<Color>(cat.iconColor),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${loc.accuracy}: ${(cat.accuracy * 100).round()}%",
                      style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${loc.avgScore}: ${cat.avgScorePercent.round()}%",
                      style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${loc.testsCompleted}: ${cat.testsCompleted}",
                      style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 11),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Category accuracy bars card
// ─────────────────────────────────────────────────────────────
class _CategoryBarsCard extends StatelessWidget {
  final AppLocalizations loc;
  final List<_CategoryStat> categories;

  const _CategoryBarsCard({required this.loc, required this.categories});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.accuracyPerCategory,
            style: const TextStyle(
              color: Color(0xFF2C015D),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            width: double.infinity,
            child: _CategoryBarChart(categories: categories),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: categories.map((c) {
              return _LegendChip(
                label: c.title,
                color: c.iconColor,
                value: "${(c.accuracy * 100).round()}%",
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _CategoryBarChart extends StatelessWidget {
  final List<_CategoryStat> categories;

  const _CategoryBarChart({required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox();

    return LayoutBuilder(
      builder: (context, constraints) {
        final barCount = categories.length;
        const spacing = 16.0;

        final barWidth = min(
          36.0,
          (constraints.maxWidth - spacing * (barCount - 1)) / barCount,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final c in categories)
              _SingleBar(
                heightFactor: c.accuracy.clamp(0.0, 1.0),
                width: barWidth,
                color: c.iconColor,
              ),
          ],
        );
      },
    );
  }
}

class _SingleBar extends StatelessWidget {
  final double heightFactor;
  final double width;
  final Color color;

  const _SingleBar({
    required this.heightFactor,
    required this.width,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: width,
          height: 110 * heightFactor,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: color.withOpacity(0.85),
          ),
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LegendChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: const Color(0xFFF4ECFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF2C015D),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Recent results card
// - NO duplicated labels (only bottom labels)
// - Fits all 7 bars/labels in one row
// - Discrete band colors (high contrast):
//   0–20 red, 20–40 yellow, 40–60 light green, 60–80 green, 80–100 dark green
// ─────────────────────────────────────────────────────────────
class _RecentResultsCard extends StatelessWidget {
  final AppLocalizations loc;
  final List<double> recentAccPct; // 0..100, oldest->newest

  const _RecentResultsCard({
    required this.loc,
    required this.recentAccPct,
  });

  Color _bandColor(double pct) {
    pct = pct.clamp(0.0, 100.0);
    if (pct < 20) return const Color(0xFFEF4444); // red
    if (pct < 40) return const Color(0xFFFACC15); // yellow
    if (pct < 60) return const Color(0xFF86EFAC); // light green
    if (pct < 80) return const Color(0xFF22C55E); // green
    return const Color(0xFF15803D); // dark green
  }

  @override
  Widget build(BuildContext context) {
    final vals = recentAccPct;

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: Color(0xFF3B82F6)),
              const SizedBox(width: 10),
              Text(
                loc.recentTests,
                style: const TextStyle(
                  color: Color(0xFF2C015D),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: _RecentBars(
              vals: vals,
              colorFn: _bandColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentBars extends StatelessWidget {
  final List<double> vals; // 0..100
  final Color Function(double pct) colorFn;

  const _RecentBars({required this.vals, required this.colorFn});

  @override
  Widget build(BuildContext context) {
    if (vals.isEmpty) return const SizedBox();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBars = vals.length;
        const spacing = 8.0;

        final rawBarWidth = (constraints.maxWidth - spacing * (maxBars - 1)) / maxBars;
        final barWidth = rawBarWidth.clamp(10.0, 22.0);

        // Keep everything within the container height:
        // bar + gap + label = <= constraints.maxHeight
        const labelH = 14.0;
        const gapH = 6.0;
        final barAreaH = max(40.0, constraints.maxHeight - labelH - gapH);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(maxBars, (i) {
            final pct = vals[i].clamp(0.0, 100.0);
            final h = barAreaH * (pct / 100.0);

            return SizedBox(
              width: barWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // bar
                  Container(
                    width: barWidth,
                    height: max(6.0, h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: colorFn(pct).withOpacity(0.92),
                    ),
                  ),
                  const SizedBox(height: gapH),
                  // bottom label (ONLY label we keep)
                  SizedBox(
                    height: labelH,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "${pct.round()}%",
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.black.withOpacity(0.75),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────
class _CategoryStat {
  final String key;
  final String title;
  final IconData icon;
  final Color iconColor;
  final int answered;
  final int correct;
  final double avgScorePercent; // 0..100
  final int testsCompleted;
  final double accuracy; // 0..1

  _CategoryStat({
    required this.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.answered,
    required this.correct,
    required this.avgScorePercent,
    required this.testsCompleted,
    required this.accuracy,
  });
}
