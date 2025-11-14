import 'dart:math';
import 'dart:ui';
import 'package:flutter/physics.dart';

import 'package:flutter/material.dart';
import 'package:secom/gen_l10n/app_localizations.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // Spring-based animation 0 → 1 with a nice overshoot/bounce.
    _controller = AnimationController.unbounded(
      vsync: this,
    );

    // Start from 0.
    _controller.value = 0.0;

    // Spring simulation to 1.0
    // (mass, stiffness, damping can be tweaked if you want stronger/weaker bounce)
    final spring = SpringSimulation(
      const SpringDescription(
        mass: 1,
        stiffness: 120,
        damping: 14,
      ),
      0.0, // start
      1.0, // end
      0.0, // initial velocity
    );

    // Run once, no looping.
    _controller.animateWith(spring);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    const purple = Color(0xFF2C015D);

    // Example current stats (will be replaced later with real data)
    final stats = <String, int>{
      'overall': 84,
      'math': 100,
      'reading': 72,
      'analogy': 70,
      'grammar': 78,
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ─────────────────────────────────────────────
              // TOP GRADIENT HEADER  (same style as Home hero)
              // ─────────────────────────────────────────────
            Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF7FB2), Color(0xFF7F4BFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  loc.statistics,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  loc.statsSubtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // ─────────────────────────────────────────
                //       RADAR AREA (with blur glow)
                // ─────────────────────────────────────────
                SizedBox(
                  height: 260,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final progress = _controller.value.clamp(0.0, 1.0).toDouble();

                      if (progress < 0.05) {
                        final opacity = 0.3 + progress * 4 * 0.4;
                        return Center(
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(opacity),
                            ),
                          ),
                        );
                      }

                      return Center(
                        child: ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 10,
                              sigmaY: 10,
                            ),
                            child: CustomPaint(
                              size: const Size(260, 260),
                              painter: _PentagonRadarPainter(
                                stats: stats,
                                context: context,
                                progress: progress,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

            const SizedBox(height: 28),

              // ─────────────────────────────────────────────
              // PROGRESS DETAIL
              // ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.statsTitle,
                      style: const TextStyle(
                        color: purple,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      loc.statsSubtitle,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _SkillCard(
                      icon: Icons.calculate_rounded,
                      title: loc.math,
                      answered: 0,
                      total: 500,
                      percent: 0,
                    ),
                    _SkillCard(
                      icon: Icons.compare_arrows_rounded,
                      title: loc.analogy,
                      answered: 0,
                      total: 300,
                      percent: 0,
                    ),
                    _SkillCard(
                      icon: Icons.menu_book_rounded,
                      title: loc.reading,
                      answered: 9,
                      total: 489,
                      percent: 1,
                    ),
                    _SkillCard(
                      icon: Icons.spellcheck_rounded,
                      title: loc.grammar,
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

//
// ██████████████████████████████████████████████████████
//   CUSTOM PENTAGON RADAR PAINTER
//   - spring-driven progress (0 → 1)
//   - blur glow (via BackdropFilter in the widget)
//   - category-colored vertices
// ██████████████████████████████████████████████████████
//
class _PentagonRadarPainter extends CustomPainter {
  final Map<String, int> stats;
  final BuildContext context;
  final double progress; // 0 → 1

  _PentagonRadarPainter({
    required this.stats,
    required this.context,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final loc = AppLocalizations.of(context)!;

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = 95.0 * progress; // scale entire radar with progress

    // Label order and localized names
    final labels = <String>[
      loc.statistics,
      loc.math,
      loc.reading,
      loc.analogy,
      loc.grammar,
    ];

    // Values in the same order
    final values = <double>[
      stats['overall']?.toDouble() ?? 0,
      stats['math']?.toDouble() ?? 0,
      stats['reading']?.toDouble() ?? 0,
      stats['analogy']?.toDouble() ?? 0,
      stats['grammar']?.toDouble() ?? 0,
    ];

    // Category colors (for vertices and maybe future legends)
    final colors = <Color>[
      const Color(0xFFFFC107), // overall  - amber
      const Color(0xFF42A5F5), // math     - blue
      const Color(0xFF66BB6A), // reading  - green
      const Color(0xFFAB47BC), // analogy  - purple
      const Color(0xFFFF7043), // grammar  - deep orange
    ];

    const int pointCount = 5;
    const double angleStep = 2 * pi / pointCount;

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.4 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Radar fill
    final fillPaint = Paint()
      ..color = Colors.amber.withOpacity(0.2 + 0.15 * progress)
      ..style = PaintingStyle.fill;

    // Radar outline
    final outlinePaint = Paint()
      ..color = Colors.amber.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Glow (slightly larger shape, tinted)
    final glowPaint = Paint()
      ..color = Colors.amber.withOpacity(0.15 * progress)
      ..style = PaintingStyle.fill;

    // ──────────────────────
    // Pentagon background rings
    // ──────────────────────
    const int rings = 5;
    for (int layer = 1; layer <= rings; layer++) {
      final radius = baseRadius * (layer / rings);
      final path = Path();
      for (int i = 0; i < pointCount; i++) {
        final ang = angleStep * i - pi / 2;
        final x = center.dx + radius * cos(ang);
        final y = center.dy + radius * sin(ang);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // ──────────────────────
    // Radar + Glow paths
    // ──────────────────────
    final radarPath = Path();
    final glowPath = Path();

    final vertexPositions = <Offset>[];

    for (int i = 0; i < pointCount; i++) {
      final percent = (values[i] / 100).clamp(0.0, 1.0);
      final r = baseRadius * percent;

      final ang = angleStep * i - pi / 2;
      final x = center.dx + r * cos(ang);
      final y = center.dy + r * sin(ang);

      // Slightly larger radius for glow
      final gx = center.dx + r * 1.05 * cos(ang);
      final gy = center.dy + r * 1.05 * sin(ang);

      vertexPositions.add(Offset(x, y));

      if (i == 0) {
        radarPath.moveTo(x, y);
        glowPath.moveTo(gx, gy);
      } else {
        radarPath.lineTo(x, y);
        glowPath.lineTo(gx, gy);
      }
    }

    radarPath.close();
    glowPath.close();

    // Draw glow first (under the radar)
    if (progress > 0.2) {
      canvas.drawPath(glowPath, glowPaint);
    }

    // Draw radar fill + outline
    canvas.drawPath(radarPath, fillPaint);
    canvas.drawPath(radarPath, outlinePaint);

    // ──────────────────────
    // Category-colored dots at vertices
    // ──────────────────────
    final vertexPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < pointCount; i++) {
      vertexPaint.color = colors[i].withOpacity(0.95);
      canvas.drawCircle(vertexPositions[i], 4.5, vertexPaint);
    }

    // ──────────────────────
    // Labels around the shape
    // ──────────────────────
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < pointCount; i++) {
      final ang = angleStep * i - pi / 2;
      final labelRadius = baseRadius + 26;
      final lx = center.dx + labelRadius * cos(ang);
      final ly = center.dy + labelRadius * sin(ang);

      textPainter.text = TextSpan(
        text: "${labels[i]}\n${values[i].round()}%",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      );

      textPainter.layout(maxWidth: 90);
      final offset =
      Offset(lx - textPainter.width / 2, ly - textPainter.height / 2);
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant _PentagonRadarPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.stats != stats;
  }
}

//
// ██████████████████████████████████████
// SKILL CARD (unchanged logic, localized)
// ██████████████████████████████████████
//
class _SkillCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int answered;
  final int total;
  final int percent;

  const _SkillCard({
    required this.icon,
    required this.title,
    required this.answered,
    required this.total,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final width = (MediaQuery.of(context).size.width - 40 - 16) / 2;

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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF4ECFF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 26, color: const Color(0xFF2C015D)),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C015D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "$answered / $total ${loc.answered}",
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  "$percent%",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  loc.correct,
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
