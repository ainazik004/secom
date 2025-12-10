import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:secom/gen_l10n/app_localizations.dart';
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
            'Not logged in',
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Text(
                  'No statistics yet',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              );
            }

            final data = snapshot.data!.data() ?? {};

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

            final totalQuestionsAnswered =
            _getNum('totalQuestionsAnswered').toInt();
            final totalCorrectAnswers =
            _getNum('totalCorrectAnswers').toInt();
            final averageScore =
            _getNum('averageScore').toDouble().clamp(0, 100);

            final categoryStats = _getMap('categoryStats');

            num _catScore(String key) {
              final cat = categoryStats[key];
              if (cat is Map<String, dynamic>) {
                final avg = cat['avgScore'];
                if (avg is num) return avg;
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

            final stats = <String, int>{
              'overall': averageScore.round(),
              'math': _catScore('math').toDouble().clamp(0, 100).round(),
              'reading':
              _catScore('reading').toDouble().clamp(0, 100).round(),
              'analogy':
              _catScore('analogy').toDouble().clamp(0, 100).round(),
              'grammar':
              _catScore('grammar').toDouble().clamp(0, 100).round(),
            };

            final mathAnswered = _catAnswered('math');
            final readingAnswered = _catAnswered('reading');
            final analogyAnswered = _catAnswered('analogy');
            final grammarAnswered = _catAnswered('grammar');

            final totalAnsweredAll =
            totalQuestionsAnswered <= 0 ? 1 : totalQuestionsAnswered;

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // -----------------------------------
                    // Header section
                    // -----------------------------------
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
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
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 35),

                          AnimatedBuilder(
                            animation: _progress,
                            builder: (_, __) {
                              final p =
                              _progress.value.clamp(0.0, 1.0);

                              return SizedBox(
                                height: 330,
                                width: double.infinity,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 260,
                                      height: 260,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            Colors.white
                                                .withOpacity(0.23 * p),
                                            Colors.transparent,
                                          ],
                                          radius: 0.75,
                                        ),
                                      ),
                                    ),
                                    CustomPaint(
                                      size: const Size(260, 260),
                                      painter: _PentagonRadarPainter(
                                        stats: stats,
                                        progress: p,
                                        context: context,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          // ---------- Advanced statistics button ----------
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
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor:
                              Colors.white.withOpacity(0.16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            icon: const Icon(
                              Icons.bar_chart_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'Advanced statistics',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // -----------------------------------
                    // Skill Cards
                    // -----------------------------------
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20),
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

// ---------------------------------------------------------
// Radar Painter
// ---------------------------------------------------------
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

    final colors = [
      const Color(0xFFFFC107),
      const Color(0xFF42A5F5),
      const Color(0xFF66BB6A),
      const Color(0xFFAB47BC),
      const Color(0xFFFF7043),
    ];

    const pointCount = 5;
    const angleStep = 2 * pi / pointCount;

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

    // Grid
    for (int layer = 1; layer <= 5; layer++) {
      final r = baseRadius * (layer / 5);
      final path = Path();
      for (int i = 0; i < pointCount; i++) {
        final ang = angleStep * i - pi / 2;
        final x = center.dx + r * cos(ang);
        final y = center.dy + r * sin(ang);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Radar polygon
    final radar = Path();
    final points = <Offset>[];

    for (int i = 0; i < pointCount; i++) {
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

    // Dots
    final dot = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < pointCount; i++) {
      dot.color = colors[i];
      canvas.drawCircle(points[i], 5, dot);
    }

    // Labels
    final tp = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < pointCount; i++) {
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
      tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _PentagonRadarPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.stats != stats;
}

// ---------------------------------------------------------
//  Skill Card WITH circular percent bar
// ---------------------------------------------------------
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
    total == 0 ? 0.0 : (answered / total).clamp(0.0, 1.0).toDouble();

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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),

                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4ECFF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: const Color(0xFF2C015D)),
                ),
                const SizedBox(height: 12),

                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF2C015D),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  "$answered / $total answered",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            Positioned(
              top: 0,
              right: 0,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: percent,
                      strokeWidth: 4,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF7F4BFF),
                      ),
                    ),
                    Text(
                      "${(percent * 100).round()}%",
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C015D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
