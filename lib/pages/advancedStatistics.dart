import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:secom/gen_l10n/app_localizations.dart';

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
              'Not logged in',
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  _AdvancedStatsHeader(
                    title: 'Advanced statistics',
                    subtitle: loc.statsSubtitle,
                  ),
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ],
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Column(
                children: [
                  _AdvancedStatsHeader(
                    title: 'Advanced statistics',
                    subtitle: loc.statsSubtitle,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'No statistics yet',
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

            // ---------- Helpers ----------
            num _getNum(String key, [num fallback = 0]) {
              final v = data[key];
              if (v is num) return v;
              return fallback;
            }

            Map<String, dynamic> _getMap(String key) {
              final v = data[key];
              if (v is Map<String, dynamic>) return v;
              return {};
            }

            // ---------- Global stats ----------
            final totalAnswered =
            _getNum('totalQuestionsAnswered').toInt().clamp(0, 1 << 31);
            final totalCorrect =
            _getNum('totalCorrectAnswers').toInt().clamp(0, totalAnswered);

            // We do not store "totalQuestions" (available). Use answered as denominator.
            final totalQuestions = totalAnswered;
            final accuracy = totalAnswered == 0
                ? 0.0
                : (totalCorrect / totalAnswered).clamp(0.0, 1.0);

            final totalTestsCompleted =
            _getNum('totalTestsCompleted').toInt().clamp(0, 1 << 31);

            final avgScorePercent =
            _getNum('averageScore').toDouble().clamp(0.0, 100.0);
            final avgScore = avgScorePercent / 100.0;

            final totalStudySeconds =
            _getNum('totalStudyTimeSeconds').toInt().clamp(0, 1 << 31);
            final totalStudyMinutes = totalStudySeconds ~/ 60;

            final avgTimePerQuestionSeconds =
            _getNum('averageTimePerQuestionSeconds')
                .toDouble()
                .clamp(0.0, 3600.0)
                .round();

            final currentStreakDays =
            _getNum('currentStreakDays').toInt().clamp(0, 36500);
            final longestStreakDays =
            _getNum('longestStreakDays').toInt().clamp(0, 36500);

            // ---------- Category accuracy ----------
            final categoryStats = _getMap('categoryStats');

            num _catAvgScore(String key) {
              final cat = categoryStats[key];
              if (cat is Map<String, dynamic>) {
                final avg = cat['avgScore'];
                if (avg is num) return avg;
              }
              return 0;
            }

            final categoryAccuracy = <String, double>{
              loc.math:
              (_catAvgScore('math').toDouble().clamp(0.0, 100.0) / 100.0),
              loc.analogy:
              (_catAvgScore('analogy').toDouble().clamp(0.0, 100.0) / 100.0),
              loc.reading:
              (_catAvgScore('reading').toDouble().clamp(0.0, 100.0) / 100.0),
              loc.grammar:
              (_catAvgScore('grammar').toDouble().clamp(0.0, 100.0) / 100.0),
            };

            // ---------- Recent tests history ----------
            // Optional field you can add later: recentTestScores: [0–100, ...]
            List<double> lastTests = [];
            final rawLastTests = data['recentTestScores'];
            if (rawLastTests is List) {
              lastTests = rawLastTests
                  .whereType<num>()
                  .map((e) => e.toDouble().clamp(0.0, 100.0) / 100.0)
                  .toList();
            }

            // Fallback: if there is no history, show a flat chart with avgScore.
            if (lastTests.isEmpty) {
              final fillCount = 7;
              lastTests = List<double>.filled(fillCount, avgScore);
            }

            return Column(
              children: [
                _AdvancedStatsHeader(
                  title: 'Advanced statistics',
                  subtitle: loc.statsSubtitle,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // OVERVIEW CARD
                        _SectionTitle(label: 'Overview'),
                        const SizedBox(height: 8),
                        _OverviewCard(
                          totalQuestions: totalQuestions,
                          totalAnswered: totalAnswered,
                          totalCorrect: totalCorrect,
                          accuracy: accuracy,
                        ),

                        const SizedBox(height: 20),

                        // CATEGORY ACCURACY
                        _SectionTitle(label: 'Category accuracy'),
                        const SizedBox(height: 8),
                        _CategoryBarsCard(
                          categoryAccuracy: categoryAccuracy,
                        ),

                        const SizedBox(height: 20),

                        // TIME & STREAK
                        _SectionTitle(label: 'Time & streaks'),
                        const SizedBox(height: 8),
                        _TimeAndStreakCard(
                          totalStudyMinutes: totalStudyMinutes,
                          avgTimePerQuestion: avgTimePerQuestionSeconds,
                          currentStreakDays: currentStreakDays,
                          longestStreakDays: longestStreakDays,
                        ),

                        const SizedBox(height: 20),

                        // TEST HISTORY
                        _SectionTitle(label: 'Recent test performance'),
                        const SizedBox(height: 8),
                        _TestHistoryCard(
                          lastTests: lastTests,
                          avgScore: avgScore,
                          totalTestsCompleted: totalTestsCompleted,
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
// Header with rounded "X" back button
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
      padding:
      const EdgeInsets.only(left: 20, right: 20, top: 18, bottom: 20),
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
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
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
          const SizedBox(width: 16),
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
                    fontWeight: FontWeight.w700,
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
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ---------------------------------------------------------
// Overview Card (accuracy donut + key stats)
// ---------------------------------------------------------
class _OverviewCard extends StatelessWidget {
  final int totalQuestions;
  final int totalAnswered;
  final int totalCorrect;
  final double accuracy;

  const _OverviewCard({
    required this.totalQuestions,
    required this.totalAnswered,
    required this.totalCorrect,
    required this.accuracy,
  });

  @override
  Widget build(BuildContext context) {
    final answeredPercent =
    totalQuestions == 0 ? 0.0 : totalAnswered / totalQuestions;

    return Container(
      padding: const EdgeInsets.all(18),
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
                    fontWeight: FontWeight.w700,
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
                const Text(
                  'Overall accuracy',
                  style: TextStyle(
                    color: Color(0xFF2C015D),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MiniStat(
                      label: 'Answered',
                      value: '$totalAnswered',
                    ),
                    const SizedBox(width: 14),
                    _MiniStat(
                      label: 'Correct',
                      value: '$totalCorrect',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: answeredPercent.clamp(0.0, 1.0),
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFFF7FB2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${(answeredPercent * 100).round()}% of all questions attempted",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.6),
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
              fontWeight: FontWeight.w700,
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
// Category accuracy card with vertical bars
// ---------------------------------------------------------
class _CategoryBarsCard extends StatelessWidget {
  final Map<String, double> categoryAccuracy;

  const _CategoryBarsCard({
    required this.categoryAccuracy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
          const Text(
            'Accuracy per category',
            style: TextStyle(
              color: Color(0xFF2C015D),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            width: double.infinity,
            child: _CategoryBarChart(categoryAccuracy: categoryAccuracy),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: categoryAccuracy.entries.map((entry) {
              return _LegendChip(
                label: entry.key,
                value: "${(entry.value * 100).round()}%",
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _CategoryBarChart extends StatelessWidget {
  final Map<String, double> categoryAccuracy;

  const _CategoryBarChart({
    required this.categoryAccuracy,
  });

  @override
  Widget build(BuildContext context) {
    final bars = categoryAccuracy.values.toList();
    if (bars.isEmpty) return const SizedBox();

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = min(
          36.0,
          (constraints.maxWidth - 16 * (bars.length - 1)) / bars.length,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (int i = 0; i < bars.length; i++)
              _SingleBar(
                heightFactor: bars[i].clamp(0.0, 1.0),
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
              fontWeight: FontWeight.w600,
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
// Time & streaks card
// ---------------------------------------------------------
class _TimeAndStreakCard extends StatelessWidget {
  final int totalStudyMinutes;
  final int avgTimePerQuestion; // seconds
  final int currentStreakDays;
  final int longestStreakDays;

  const _TimeAndStreakCard({
    required this.totalStudyMinutes,
    required this.avgTimePerQuestion,
    required this.currentStreakDays,
    required this.longestStreakDays,
  });

  @override
  Widget build(BuildContext context) {
    final hours = totalStudyMinutes ~/ 60;
    final minutes = totalStudyMinutes % 60;

    return Container(
      padding: const EdgeInsets.all(18),
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
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  color: Color(0xFF7F4BFF)),
              const SizedBox(width: 10),
              const Text(
                'Study time & pacing',
                style: TextStyle(
                  color: Color(0xFF2C015D),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _BigNumberStat(
                title: 'Total study time',
                value: hours > 0
                    ? '${hours}h ${minutes}m'
                    : '${minutes} min',
              ),
              const SizedBox(width: 16),
              _BigNumberStat(
                title: 'Avg time / question',
                value: '${avgTimePerQuestion}s',
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: Color(0xFFFF7A5C),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    _BigNumberStat(
                      title: 'Current streak',
                      value: '${currentStreakDays} days',
                    ),
                    const SizedBox(width: 16),
                    _BigNumberStat(
                      title: 'Longest streak',
                      value: '${longestStreakDays} days',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BigNumberStat extends StatelessWidget {
  final String title;
  final String value;

  const _BigNumberStat({
    required this.title,
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
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
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
// Test history card with small bar chart
// ---------------------------------------------------------
class _TestHistoryCard extends StatelessWidget {
  final List<double> lastTests; // 0.0-1.0
  final double avgScore;
  final int totalTestsCompleted;

  const _TestHistoryCard({
    required this.lastTests,
    required this.avgScore,
    required this.totalTestsCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded,
                  color: Color(0xFF42A5F5)),
              const SizedBox(width: 10),
              const Text(
                'Recent tests',
                style: TextStyle(
                  color: Color(0xFF2C015D),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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
              _BigNumberStat(
                title: 'Average score',
                value: '${(avgScore * 100).round()}%',
              ),
              const SizedBox(width: 16),
              _BigNumberStat(
                title: 'Tests completed',
                value: '$totalTestsCompleted',
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

  const _MiniTestBarChart({
    required this.lastTests,
  });

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
                    0.4 + 0.4 * lastTests[i].clamp(0.0, 1.0),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
