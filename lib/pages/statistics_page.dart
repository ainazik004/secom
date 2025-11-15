import 'dart:math';
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

    // Trigger animation after page is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final stats = {
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
              // -----------------------------------
              // Header section
              // -----------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF7FB2), Color(0xFF7F4BFF)],
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

                    // -----------------------------------
                    // Radar chart with no clipping
                    // -----------------------------------
                    AnimatedBuilder(
                      animation: _progress,
                      builder: (_, __) {
                        final p = _progress.value.clamp(0.0, 1.0);

                        return SizedBox(
                          height: 330,
                          width: double.infinity,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Soft radial glow (NO RECTANGLE EDGES)
                              Container(
                                width: 260,
                                height: 260,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.23 * p),
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
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // -----------------------------------
              // Skill cards grid
              // -----------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _SkillCard(
                      title: loc.math,
                      icon: Icons.calculate_rounded,
                      answered: 0,
                      total: 500,
                      percent: 0,
                    ),
                    _SkillCard(
                      title: loc.analogy,
                      icon: Icons.compare_arrows_rounded,
                      answered: 0,
                      total: 300,
                      percent: 0,
                    ),
                    _SkillCard(
                      title: loc.reading,
                      icon: Icons.menu_book_rounded,
                      answered: 9,
                      total: 489,
                      percent: 1,
                    ),
                    _SkillCard(
                      title: loc.grammar,
                      icon: Icons.spellcheck_rounded,
                      answered: 0,
                      total: 600,
                      percent: 0,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// Radar painter — text NEVER clipped
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

    // Grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke;

    // Fill
    final fillPaint = Paint()
      ..color = Colors.amber.withOpacity(0.22)
      ..style = PaintingStyle.fill;

    // Outline
    final outlinePaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw rings
    for (int layer = 1; layer <= 5; layer++) {
      final r = baseRadius * (layer / 5);
      final path = Path();
      for (int i = 0; i < pointCount; i++) {
        final ang = angleStep * i - pi / 2;
        final x = center.dx + r * cos(ang);
        final y = center.dy + r * sin(ang);
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Radar path
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
      i == 0 ? radar.moveTo(pt.dx, pt.dy) : radar.lineTo(pt.dx, pt.dy);
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

    // Labels (farther from edges)
    final tp = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < pointCount; i++) {
      final ang = angleStep * i - pi / 2;
      final labelRadius = baseRadius + 44; // *** Further away ***

      final lx = center.dx + labelRadius * cos(ang);
      final ly = center.dy + labelRadius * sin(ang);

      tp.text = TextSpan(
        text: "${labels[i]}\n${values[i]}%",
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

// ---------------------------------------------------------
// Skill Card
// ---------------------------------------------------------
class _SkillCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int answered;
  final int total;
  final int percent;

  const _SkillCard({
    required this.title,
    required this.icon,
    required this.answered,
    required this.total,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

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
              "$answered / $total ${loc.answered}",
              style: TextStyle(
                color: Colors.black.withOpacity(0.6),
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 6),

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
