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
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            final header = _AdvancedStatsHeader(
              title: loc.advancedStatisticsTitle,
              subtitle: loc.statsSubtitle,
            );

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  header,
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
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

            final data = snapshot.data!.data() ?? {};

            // ---------- Typed helpers ----------
            num _num(String key, [num fallback = 0]) {
              final v = data[key];
              return v is num ? v : fallback;
            }

            String? _str(String key) {
              final v = data[key];
              return v is String && v.trim().isNotEmpty ? v : null;
            }

            bool _bool(String key, [bool fallback = false]) {
              final v = data[key];
              return v is bool ? v : fallback;
            }

            Map<String, dynamic> _map(String key) {
              final v = data[key];
              return v is Map<String, dynamic> ? v : <String, dynamic>{};
            }

            DateTime? _timestamp(String key) {
              final v = data[key];
              if (v is Timestamp) return v.toDate();
              return null;
            }

            // ---------- Global stats (from your fields) ----------
            final totalAnswered =
            _num('totalQuestionsAnswered').toInt().clamp(0, 1 << 31);
            final totalCorrect =
            _num('totalCorrectAnswers').toInt().clamp(0, totalAnswered);

            final accuracy = totalAnswered == 0
                ? 0.0
                : (totalCorrect / totalAnswered).clamp(0.0, 1.0);

            final avgScorePercent =
            _num('averageScore').toDouble().clamp(0.0, 100.0);
            final avgScore = avgScorePercent / 100.0;

            final avgTimePerQuestionSeconds = _num('averageTimePerQuestionSeconds')
                .toDouble()
                .clamp(0.0, 3600.0);

            final totalStudySeconds =
            _num('totalStudyTimeSeconds').toInt().clamp(0, 1 << 31);

            final currentStreakDays =
            _num('currentStreakDays').toInt().clamp(0, 36500);
            final longestStreakDays =
            _num('longestStreakDays').toInt().clamp(0, 36500);

            final trophies = _num('trophies').toInt().clamp(0, 1 << 31);

            final totalTestsCompleted =
            _num('totalTestsCompleted').toInt().clamp(0, 1 << 31);

            final lastLoginAt = _timestamp('lastLoginAt');
            final lastUpdatedAt = _timestamp('lastUpdatedAt');

            final lastTestDateStr = _str('lastTestDate'); // "2026-01-09" in your example

            final appVersion = _str('appVersion');
            final authProvider = _str('authProvider');

            final isPremium = _bool('isPremium', false);
            final emailVerified = _bool('emailVerified', false); // you also have isEmailVerified
            final languageCode = _str('languageCode');
            final theme = _str('theme');
            final notificationsEnabled = _bool('notificationsEnabled', true);

            // ---------- Category stats ----------
            final categoryStats = _map('categoryStats');

            Map<String, dynamic> _cat(String key) {
              final v = categoryStats[key];
              return v is Map<String, dynamic> ? v : <String, dynamic>{};
            }

            int _catAnswered(String key) {
              final v = _cat(key)['answered'];
              return v is num ? v.toInt() : 0;
            }

            int _catCorrect(String key) {
              final v = _cat(key)['correct'];
              return v is num ? v.toInt() : 0;
            }

            int _catTests(String key) {
              final v = _cat(key)['testsCompleted'];
              return v is num ? v.toInt() : 0;
            }

            double _catAvgScore(String key) {
              final v = _cat(key)['avgScore'];
              return v is num ? v.toDouble().clamp(0.0, 100.0) : 0.0;
            }

            double _catAccuracy(String key) {
              final a = _catAnswered(key);
              final c = _catCorrect(key).clamp(0, a);
              if (a == 0) return 0.0;
              return (c / a).clamp(0.0, 1.0);
            }

            final categories = <_CategoryStat>[
              _CategoryStat(
                key: 'math',
                title: loc.math,
                icon: Icons.calculate_rounded,
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
                answered: _catAnswered('grammar'),
                correct: _catCorrect('grammar'),
                avgScorePercent: _catAvgScore('grammar'),
                testsCompleted: _catTests('grammar'),
                accuracy: _catAccuracy('grammar'),
              ),
            ];

            // ---------- Recent tests history (optional) ----------
            List<double> lastTests = [];
            final rawLastTests = data['recentTestScores'];
            if (rawLastTests is List) {
              lastTests = rawLastTests
                  .whereType<num>()
                  .map((e) => (e.toDouble().clamp(0.0, 100.0) / 100.0))
                  .toList();
            }
            if (lastTests.isEmpty) {
              lastTests = List<double>.filled(7, avgScore);
            } else if (lastTests.length > 14) {
              lastTests = lastTests.sublist(lastTests.length - 14);
            }

            // ---------- Formatting ----------
            final matLoc = MaterialLocalizations.of(context);

            String fmtDateTime(DateTime? dt) {
              if (dt == null) return loc.notAvailable;
              final d = matLoc.formatShortDate(dt);
              final t = matLoc.formatTimeOfDay(TimeOfDay.fromDateTime(dt),
                  alwaysUse24HourFormat: true);
              return "$d  $t";
            }

            String fmtDurationMinutes(int seconds) {
              final totalMinutes = seconds ~/ 60;
              final h = totalMinutes ~/ 60;
              final m = totalMinutes % 60;
              if (h <= 0) return "${m} ${loc.minutes}";
              return "${h} ${loc.hours} ${m} ${loc.minutes}";
            }

            String fmtSeconds(double s) {
              return "${s.round()} ${loc.seconds}";
            }

            String fmtBool(bool v) => v ? loc.yes : loc.no;

            // ---------- Layout ----------
            return Column(
              children: [
                header,
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                          avgTimePerQuestionLabel: fmtSeconds(avgTimePerQuestionSeconds),
                          totalStudyLabel: fmtDurationMinutes(totalStudySeconds),
                        ),

                        const SizedBox(height: 14),

                        _QuickFactsCard(
                          loc: loc,
                          trophies: trophies,
                          totalTestsCompleted: totalTestsCompleted,
                          currentStreakDays: currentStreakDays,
                          longestStreakDays: longestStreakDays,
                          lastLogin: fmtDateTime(lastLoginAt),
                          lastUpdated: fmtDateTime(lastUpdatedAt),
                          lastTestDate: lastTestDateStr ?? loc.notAvailable,
                        ),

                        const SizedBox(height: 22),

                        _SectionTitle(label: loc.categoryBreakdown),
                        const SizedBox(height: 8),

                        _CategoryCardsGrid(
                          loc: loc,
                          categories: categories,
                        ),

                        const SizedBox(height: 20),

                        _CategoryBarsCard(
                          loc: loc,
                          categories: categories,
                        ),

                        const SizedBox(height: 20),

                        _SectionTitle(label: loc.recentTestPerformance),
                        const SizedBox(height: 8),

                        _TestHistoryCard(
                          loc: loc,
                          lastTests: lastTests,
                          avgScore: avgScore,
                          totalTestsCompleted: totalTestsCompleted,
                        ),

                        const SizedBox(height: 20),

                        _SectionTitle(label: loc.accountAndSettings),
                        const SizedBox(height: 8),

                        _AccountCard(
                          loc: loc,
                          appVersion: appVersion ?? loc.notAvailable,
                          authProvider: authProvider ?? loc.notAvailable,
                          isPremium: fmtBool(isPremium),
                          emailVerified: fmtBool(emailVerified),
                          languageCode: languageCode ?? loc.notAvailable,
                          theme: theme ?? loc.notAvailable,
                          notificationsEnabled: fmtBool(notificationsEnabled),
                        ),

                        const SizedBox(height: 32),
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
}

// ---------------------------------------------------------
// Header
// ---------------------------------------------------------
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
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
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
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 20,
              ),
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
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
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

// ---------------------------------------------------------
// Section title
// ---------------------------------------------------------
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

// ---------------------------------------------------------
// Overview card
// ---------------------------------------------------------
class _OverviewCard extends StatelessWidget {
  final AppLocalizations loc;
  final double accuracy;
  final int totalAnswered;
  final int totalCorrect;
  final double avgScorePercent;
  final String avgTimePerQuestionLabel;
  final String totalStudyLabel;

  const _OverviewCard({
    required this.loc,
    required this.accuracy,
    required this.totalAnswered,
    required this.totalCorrect,
    required this.avgScorePercent,
    required this.avgTimePerQuestionLabel,
    required this.totalStudyLabel,
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
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF7F4BFF),
                  ),
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
                    _MiniStat(
                      label: loc.answered,
                      value: "$totalAnswered",
                    ),
                    const SizedBox(width: 14),
                    _MiniStat(
                      label: loc.correct,
                      value: "$totalCorrect",
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _MiniStat(
                      label: loc.avgScore,
                      value: "${avgScorePercent.round()}%",
                    ),
                    const SizedBox(width: 14),
                    _MiniStat(
                      label: loc.avgTimePerQuestion,
                      value: avgTimePerQuestionLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "${loc.studyTime}: $totalStudyLabel",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.65),
                    fontSize: 11,
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

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({
    required this.label,
    required this.value,
  });

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
            style: TextStyle(
              color: Colors.black.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// Quick facts card
// ---------------------------------------------------------
class _QuickFactsCard extends StatelessWidget {
  final AppLocalizations loc;
  final int trophies;
  final int totalTestsCompleted;
  final int currentStreakDays;
  final int longestStreakDays;
  final String lastLogin;
  final String lastUpdated;
  final String lastTestDate;

  const _QuickFactsCard({
    required this.loc,
    required this.trophies,
    required this.totalTestsCompleted,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.lastLogin,
    required this.lastUpdated,
    required this.lastTestDate,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RowStat(
            icon: Icons.emoji_events_rounded,
            title: loc.trophies,
            value: "$trophies",
          ),
          const SizedBox(height: 10),
          _RowStat(
            icon: Icons.fact_check_rounded,
            title: loc.testsCompleted,
            value: "$totalTestsCompleted",
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _RowStat(
                  icon: Icons.local_fire_department_rounded,
                  title: loc.currentStreak,
                  value: "$currentStreakDays ${loc.days}",
                  compact: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RowStat(
                  icon: Icons.whatshot_rounded,
                  title: loc.longestStreak,
                  value: "$longestStreakDays ${loc.days}",
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _RowStat(
            icon: Icons.login_rounded,
            title: loc.lastLogin,
            value: lastLogin,
          ),
          const SizedBox(height: 10),
          _RowStat(
            icon: Icons.update_rounded,
            title: loc.lastUpdated,
            value: lastUpdated,
          ),
          const SizedBox(height: 10),
          _RowStat(
            icon: Icons.event_rounded,
            title: loc.lastTestDate,
            value: lastTestDate,
          ),
        ],
      ),
    );
  }
}

class _RowStat extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool compact;

  const _RowStat({
    required this.icon,
    required this.title,
    required this.value,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF7F4BFF)),
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

// ---------------------------------------------------------
// Category cards grid
// ---------------------------------------------------------
class _CategoryCardsGrid extends StatelessWidget {
  final AppLocalizations loc;
  final List<_CategoryStat> categories;

  const _CategoryCardsGrid({
    required this.loc,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 56) / 2;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: categories.map((c) {
        return SizedBox(
          width: width,
          child: _CardShell(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(c.icon, color: const Color(0xFF2C015D)),
                const SizedBox(height: 10),
                Text(
                  c.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF2C015D),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${loc.correct}: ${c.correct}",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.65),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${loc.answered}: ${c.answered}",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.65),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: c.accuracy,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFECE7FF),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${loc.accuracy}: ${(c.accuracy * 100).round()}%   •   ${loc.avgScore}: ${c.avgScorePercent.round()}%",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${loc.testsCompleted}: ${c.testsCompleted}",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------
// Category accuracy bars card
// ---------------------------------------------------------
class _CategoryBarsCard extends StatelessWidget {
  final AppLocalizations loc;
  final List<_CategoryStat> categories;

  const _CategoryBarsCard({
    required this.loc,
    required this.categories,
  });

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
        final barWidth = min(
          36.0,
          (constraints.maxWidth - 16 * (barCount - 1)) / barCount,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final c in categories)
              _SingleBar(
                heightFactor: c.accuracy.clamp(0.0, 1.0),
                width: barWidth,
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

  const _SingleBar({
    required this.heightFactor,
    required this.width,
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
            gradient: const LinearGradient(
              colors: [
                Color(0xFF7F4BFF),
                Color(0xFFFF7FB2),
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final String label;
  final String value;

  const _LegendChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: const Color(0xFFF4ECFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            style: TextStyle(
              color: Colors.black.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// Test history card
// ---------------------------------------------------------
class _TestHistoryCard extends StatelessWidget {
  final AppLocalizations loc;
  final List<double> lastTests; // 0.0-1.0
  final double avgScore; // 0.0-1.0
  final int totalTestsCompleted;

  const _TestHistoryCard({
    required this.loc,
    required this.lastTests,
    required this.avgScore,
    required this.totalTestsCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: Color(0xFF42A5F5)),
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
            height: 90,
            width: double.infinity,
            child: _MiniTestBarChart(lastTests: lastTests),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat(
                label: loc.avgScore,
                value: "${(avgScore * 100).round()}%",
              ),
              const SizedBox(width: 14),
              _MiniStat(
                label: loc.testsCompleted,
                value: "$totalTestsCompleted",
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniTestBarChart extends StatelessWidget {
  final List<double> lastTests;

  const _MiniTestBarChart({required this.lastTests});

  @override
  Widget build(BuildContext context) {
    if (lastTests.isEmpty) return const SizedBox();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBars = lastTests.length;
        final barWidth = min(
          14.0,
          (constraints.maxWidth - 8 * (maxBars - 1)) / maxBars,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (int i = 0; i < maxBars; i++)
              Container(
                width: barWidth,
                height: 70 * lastTests[i].clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF42A5F5).withOpacity(
                    0.35 + 0.45 * lastTests[i].clamp(0.0, 1.0),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------
// Account/settings card
// ---------------------------------------------------------
class _AccountCard extends StatelessWidget {
  final AppLocalizations loc;
  final String appVersion;
  final String authProvider;
  final String isPremium;
  final String emailVerified;
  final String languageCode;
  final String theme;
  final String notificationsEnabled;

  const _AccountCard({
    required this.loc,
    required this.appVersion,
    required this.authProvider,
    required this.isPremium,
    required this.emailVerified,
    required this.languageCode,
    required this.theme,
    required this.notificationsEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        children: [
          _RowStat(
            icon: Icons.apps_rounded,
            title: loc.appVersion,
            value: appVersion,
          ),
          const SizedBox(height: 10),
          _RowStat(
            icon: Icons.lock_rounded,
            title: loc.authProvider,
            value: authProvider,
          ),
          const SizedBox(height: 10),
          _RowStat(
            icon: Icons.workspace_premium_rounded,
            title: loc.premium,
            value: isPremium,
          ),
          const SizedBox(height: 10),
          _RowStat(
            icon: Icons.verified_rounded,
            title: loc.emailVerified,
            value: emailVerified,
          ),
          const SizedBox(height: 10),
          _RowStat(
            icon: Icons.language_rounded,
            title: loc.language,
            value: languageCode,
          ),
          const SizedBox(height: 10),
          _RowStat(
            icon: Icons.palette_rounded,
            title: loc.theme,
            value: theme,
          ),
          const SizedBox(height: 10),
          _RowStat(
            icon: Icons.notifications_active_rounded,
            title: loc.notifications,
            value: notificationsEnabled,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// Card shell
// ---------------------------------------------------------
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

// ---------------------------------------------------------
// Models
// ---------------------------------------------------------
class _CategoryStat {
  final String key;
  final String title;
  final IconData icon;
  final int answered;
  final int correct;
  final double avgScorePercent; // 0..100
  final int testsCompleted;
  final double accuracy; // 0..1

  _CategoryStat({
    required this.key,
    required this.title,
    required this.icon,
    required this.answered,
    required this.correct,
    required this.avgScorePercent,
    required this.testsCompleted,
    required this.accuracy,
  });
}
