import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';
import 'advancedStatistics.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FF),
      body: SafeArea(
        child: user == null
            ? Center(
          child: Text(
            loc.notLoggedIn,
            style: TextStyle(
              color: Colors.black.withOpacity(0.6),
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
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Text(
                  loc.noStatisticsYet,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              );
            }

            final data = snapshot.data!.data() ?? {};
            final categoryStats =
                (data['categoryStats'] as Map<String, dynamic>?) ?? {};

            num _catAvg(String key) {
              final cat = categoryStats[key];
              if (cat is Map<String, dynamic>) {
                final avg = cat['avgScore'];
                if (avg is num) return avg.clamp(0, 100);
              }
              return 0;
            }

            int _catAnswered(String key) {
              final cat = categoryStats[key];
              if (cat is Map<String, dynamic>) {
                final a = cat['answered'];
                if (a is num) return a.toInt();
              }
              return 0;
            }

            double _computeOverallAverage() {
              final keys = ['math', 'reading', 'analogy', 'grammar'];
              final values = <double>[];

              for (final k in keys) {
                final answered = _catAnswered(k);
                final avg = _catAvg(k).toDouble();
                if (answered > 0) {
                  values.add(avg);
                }
              }

              if (values.isEmpty) return 0.0;
              return values.reduce((a, b) => a + b) / values.length;
            }

            final overallAvg =
            _computeOverallAverage().round();

            final stats = <String, int>{
              'overall': overallAvg,
              'math': _catAvg('math').round(),
              'reading': _catAvg('reading').round(),
              'analogy': _catAvg('analogy').round(),
              'grammar': _catAvg('grammar').round(),
            };

            final mathAnswered = _catAnswered('math');
            final readingAnswered = _catAnswered('reading');
            final analogyAnswered = _catAnswered('analogy');
            final grammarAnswered = _catAnswered('grammar');

            final totalAnsweredAll = [
              mathAnswered,
              readingAnswered,
              analogyAnswered,
              grammarAnswered,
            ].reduce((a, b) => a + b);

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics:
                const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // ───────── HEADER ─────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 32),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFF7FB2),
                            Color(0xFF7F4BFF)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(
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
                          const SizedBox(height: 6),
                          Text(
                            loc.statsSubtitle,
                            style: TextStyle(
                              color: Colors.white
                                  .withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 35),

                          AnimatedBuilder(
                            animation: _progress,
                            builder: (_, __) {
                              final p = _progress.value
                                  .clamp(0.0, 1.0);

                              return SizedBox(
                                height: 330,
                                child: CustomPaint(
                                  size:
                                  const Size(260, 260),
                                  painter:
                                  _PentagonRadarPainter(
                                    stats: stats,
                                    progress: p,
                                    context: context,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                  const AdvancedStatisticsPage(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.bar_chart_rounded,
                              size: 18,
                            ),
                            label: Text(
                              loc.advancedStatistics,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _SkillCard(
                            title: loc.math,
                            icon: Icons.calculate_rounded,
                            answered: mathAnswered,
                            total: totalAnsweredAll,
                          ),
                          _SkillCard(
                            title: loc.analogy,
                            icon: Icons.compare_arrows_rounded,
                            answered: analogyAnswered,
                            total: totalAnsweredAll,
                          ),
                          _SkillCard(
                            title: loc.reading,
                            icon: Icons.menu_book_rounded,
                            answered: readingAnswered,
                            total: totalAnsweredAll,
                          ),
                          _SkillCard(
                            title: loc.grammar,
                            icon: Icons.spellcheck_rounded,
                            answered: grammarAnswered,
                            total: totalAnsweredAll,
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

/* ─────────────────────────────────────────
   RADAR + SKILL CARD CLASSES
   (UNCHANGED FROM YOUR VERSION)
───────────────────────────────────────── */

class _PentagonRadarPainter extends CustomPainter {
  final Map<String, int> stats;
  final double progress;
  final BuildContext context;

  _PentagonRadarPainter({
    required this.stats,
    required this.progress,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final loc = AppLocalizations.of(context)!;

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = 70 * progress;

    final labels = [
      loc.statistics,
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

    const angleStep = 2 * pi / 5;

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.amber.withOpacity(0.22)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int layer = 1; layer <= 5; layer++) {
      final r = baseRadius * (layer / 5);
      final path = Path();
      for (int i = 0; i < 5; i++) {
        final ang = angleStep * i - pi / 2;
        final p = Offset(
          center.dx + r * cos(ang),
          center.dy + r * sin(ang),
        );
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
    final points = <Offset>[];

    for (int i = 0; i < 5; i++) {
      final r = baseRadius * (values[i] / 100);
      final ang = angleStep * i - pi / 2;
      final pt = Offset(
        center.dx + r * cos(ang),
        center.dy + r * sin(ang),
      );
      points.add(pt);
      if (i == 0) {
        radar.moveTo(pt.dx, pt.dy);
      } else {
        radar.lineTo(pt.dx, pt.dy);
      }
    }

    radar.close();
    canvas.drawPath(radar, fillPaint);
    canvas.drawPath(radar, outlinePaint);

    for (final p in points) {
      canvas.drawCircle(p, 5, Paint()..color = Colors.white);
    }

    final tp = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < 5; i++) {
      final ang = angleStep * i - pi / 2;
      final labelRadius = baseRadius + 44;
      final lx = center.dx + labelRadius * cos(ang);
      final ly = center.dy + labelRadius * sin(ang);

      tp.text = TextSpan(
        text: "${labels[i]}\n${values[i].round()}%",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );

      tp.layout(maxWidth: 130);
      tp.paint(
        canvas,
        Offset(lx - tp.width / 2, ly - tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PentagonRadarPainter oldDelegate) =>
      oldDelegate.progress != progress ||
          oldDelegate.stats != stats;
}

class _SkillCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int answered;
  final int total;

  const _SkillCard({
    required this.title,
    required this.icon,
    required this.answered,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percent =
    total == 0 ? 0.0 : (answered / total).clamp(0.0, 1.0);

    final width = (MediaQuery.of(context).size.width - 56) / 2;

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
            Icon(icon, color: const Color(0xFF2C015D)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "$answered / $total",
              style: TextStyle(
                color: Colors.black.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
