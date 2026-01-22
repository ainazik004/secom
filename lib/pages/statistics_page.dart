import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';
import 'advancedStatistics.dart';

// ✅ Reuse the same hero gradients as Home (so colors are NOT inverted between themes)
const LinearGradient zHeroGradientLight = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFFF5FA2),
    Color(0xFF9B7CFF),
  ],
);

const LinearGradient zHeroGradientDark = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFFF3D7F),
    Color(0xFF2C015D),
  ],
);

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    _controller.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    // ✅ theme-based background
    final bg = cs.surface;

    // ✅ theme-based text colors
    final muted = cs.onSurface.withOpacity(isDark ? 0.72 : 0.60);

    // ✅ theme-based header gradient (same direction as Home)
    final headerGradient = isDark ? zHeroGradientDark : zHeroGradientLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: user == null
            ? Center(
          child: Text(
            loc.notLoggedIn,
            style: TextStyle(
              color: muted,
              fontSize: 14,
            ),
          ),
        )
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Text(
                  loc.noStatisticsYet,
                  style: TextStyle(
                    color: muted,
                    fontSize: 14,
                  ),
                ),
              );
            }

            final data = snapshot.data!.data() ?? {};
            final categoryStats =
                (data['categoryStats'] as Map<String, dynamic>?) ?? {};

            Map<String, dynamic> _cat(String key) {
              final v = categoryStats[key];
              return v is Map<String, dynamic> ? v : <String, dynamic>{};
            }

            int _answered(String key) {
              final v = _cat(key)['answered'];
              return v is num ? v.toInt() : 0;
            }

            int _correct(String key) {
              final v = _cat(key)['correct'];
              return v is num ? v.toInt() : 0;
            }

            double _avgScore(String key) {
              final v = _cat(key)['avgScore'];
              return v is num ? v.toDouble().clamp(0.0, 100.0) : 0.0;
            }

            // Category values (each is isolated, not mixed)
            final mathAnswered = _answered('math');
            final readingAnswered = _answered('reading');
            final analogyAnswered = _answered('analogy');
            final grammarAnswered = _answered('grammar');

            final mathCorrect = _correct('math');
            final readingCorrect = _correct('reading');
            final analogyCorrect = _correct('analogy');
            final grammarCorrect = _correct('grammar');

            // Radar uses avgScore per category, overall = average of those 4 values
            final mathAvg = _avgScore('math');
            final readingAvg = _avgScore('reading');
            final analogyAvg = _avgScore('analogy');
            final grammarAvg = _avgScore('grammar');

            final overallAvg =
            ((mathAvg + readingAvg + analogyAvg + grammarAvg) / 4.0)
                .clamp(0.0, 100.0)
                .round();

            final radarStats = <String, int>{
              'overall': overallAvg,
              'math': mathAvg.round(),
              'reading': readingAvg.round(),
              'analogy': analogyAvg.round(),
              'grammar': grammarAvg.round(),
            };

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // ───────── HEADER ─────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        gradient: headerGradient,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            loc.statistics,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 30),
                          AnimatedBuilder(
                            animation: _progress,
                            builder: (_, __) {
                              return SizedBox(
                                height: 300,
                                child: CustomPaint(
                                  size: const Size(260, 260),
                                  painter: _PentagonRadarPainter(
                                    stats: radarStats,
                                    progress: _progress.value,
                                    context: context,
                                    // ✅ use theme colors instead of hardcoded amber
                                    fillColor: cs.tertiary.withOpacity(0.25),
                                    strokeColor: cs.tertiary,
                                    labelColor: Colors.white,
                                    gridColor: Colors.white.withOpacity(0.35),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _PrimaryActionButton(
                            label: loc.advancedStatistics,
                            icon: Icons.bar_chart_rounded,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                  const AdvancedStatisticsPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ───────── CATEGORY CARDS ─────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _SkillCard(
                            title: loc.math,
                            icon: Icons.calculate_rounded,
                            correct: mathCorrect,
                            answered: mathAnswered,
                          ),
                          _SkillCard(
                            title: loc.analogy,
                            icon: Icons.compare_arrows_rounded,
                            correct: analogyCorrect,
                            answered: analogyAnswered,
                          ),
                          _SkillCard(
                            title: loc.reading,
                            icon: Icons.menu_book_rounded,
                            correct: readingCorrect,
                            answered: readingAnswered,
                          ),
                          _SkillCard(
                            title: loc.grammar,
                            icon: Icons.spellcheck_rounded,
                            correct: grammarCorrect,
                            answered: grammarAnswered,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/* ───────────────────────── RADAR ───────────────────────── */

class _PentagonRadarPainter extends CustomPainter {
  final Map<String, int> stats;
  final double progress;
  final BuildContext context;

  // ✅ theme-driven colors (no hardcoded amber)
  final Color fillColor;
  final Color strokeColor;
  final Color labelColor;
  final Color gridColor;

  _PentagonRadarPainter({
    required this.stats,
    required this.progress,
    required this.context,
    required this.fillColor,
    required this.strokeColor,
    required this.labelColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final loc = AppLocalizations.of(context)!;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = 70 * progress;
    const step = 2 * pi / 5;

    final labels = [
      loc.average,
      loc.math,
      loc.reading,
      loc.analogy,
      loc.grammar,
    ];

    final values = [
      stats['overall']!.toDouble(),
      stats['math']!.toDouble(),
      stats['reading']!.toDouble(),
      stats['analogy']!.toDouble(),
      stats['grammar']!.toDouble(),
    ];

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke;

    for (int layer = 1; layer <= 5; layer++) {
      final r = radius * (layer / 5);
      final path = Path();
      for (int i = 0; i < 5; i++) {
        final a = step * i - pi / 2;
        final p = center + Offset(r * cos(a), r * sin(a));
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    final radar = Path();
    for (int i = 0; i < 5; i++) {
      final r = radius * (values[i] / 100.0);
      final a = step * i - pi / 2;
      final p = center + Offset(r * cos(a), r * sin(a));
      if (i == 0) {
        radar.moveTo(p.dx, p.dy);
      } else {
        radar.lineTo(p.dx, p.dy);
      }
    }
    radar.close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(radar, fillPaint);
    canvas.drawPath(radar, outlinePaint);

    final tp = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < 5; i++) {
      final a = step * i - pi / 2;
      final pos =
          center + Offset((radius + 44) * cos(a), (radius + 44) * sin(a));

      tp.text = TextSpan(
        text: "${labels[i]}\n${values[i].round()}%",
        style: TextStyle(
          color: labelColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
      tp.layout(maxWidth: 120);
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _PentagonRadarPainter oldDelegate) =>
      oldDelegate.progress != progress ||
          oldDelegate.stats != stats ||
          oldDelegate.fillColor != fillColor ||
          oldDelegate.strokeColor != strokeColor ||
          oldDelegate.gridColor != gridColor ||
          oldDelegate.labelColor != labelColor;
}

/* ───────────────────────── CARD ───────────────────────── */

class _SkillCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int correct;
  final int answered;

  const _SkillCard({
    required this.title,
    required this.icon,
    required this.correct,
    required this.answered,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final isDark = cs.brightness == Brightness.dark;
    final surface = cs.surface;
    final border = cs.outlineVariant.withOpacity(isDark ? 0.55 : 0.70);
    final titleColor = cs.onSurface;
    final muted = cs.onSurfaceVariant.withOpacity(isDark ? 0.78 : 0.70);

    final accuracy =
    answered == 0 ? 0.0 : (correct / answered).clamp(0.0, 1.0);

    final width = (MediaQuery.of(context).size.width - 56) / 2;

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border, width: 1),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(isDark ? 0.22 : 0.10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),

            Text(
              "${loc.correct}: $correct",
              style: TextStyle(
                color: muted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "${loc.answered}: $answered",
              style: TextStyle(
                color: muted,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: accuracy,
                minHeight: 7,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ───────────────────────── BUTTON ───────────────────────── */

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        backgroundColor: cs.tertiary,
        foregroundColor: cs.onTertiary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        elevation: 0,
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
