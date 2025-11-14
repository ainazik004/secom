import 'dart:math';
import 'package:flutter/material.dart';

class RadarChart extends StatefulWidget {
  final Map<String, double> values; // 0–100 percentages
  final List<String> labels;

  const RadarChart({
    super.key,
    required this.values,
    required this.labels,
  });

  @override
  State<RadarChart> createState() => _RadarChartState();
}

class _RadarChartState extends State<RadarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.forward(); // play on load
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        return CustomPaint(
          painter: _RadarPainter(
            values: widget.values,
            labels: widget.labels,
            progress: _animation.value,
          ),
        );
      },
    );
  }
}

class _RadarPainter extends CustomPainter {
  final Map<String, double> values;
  final List<String> labels;
  final double progress;

  _RadarPainter({
    required this.values,
    required this.labels,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;
    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const int count = 5; // pentagon
    const double fullCircle = 2 * pi;

    // Draw grid rings
    for (int i = 1; i <= 5; i++) {
      double r = radius * (i / 5);
      _drawPolygon(canvas, center, r, count, gridPaint);
    }

    // Draw connecting polygon (animated)
    final path = Path();
    bool first = true;

    for (int i = 0; i < count; i++) {
      double angle = fullCircle * i / count - pi / 2;
      double percent = values[labels[i]] ?? 0;
      double r = radius * (percent / 100) * progress;

      Offset point = Offset(
        center.dx + r * cos(angle),
        center.dy + r * sin(angle),
      );

      if (first) {
        path.moveTo(point.dx, point.dy);
        first = false;
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    final fillPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);

    // Draw text labels
    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );

    for (int i = 0; i < count; i++) {
      double angle = fullCircle * i / count - pi / 2;
      double tx = center.dx + (radius + 22) * cos(angle);
      double ty = center.dy + (radius + 22) * sin(angle);

      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(tx - tp.width / 2, ty - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }

  void _drawPolygon(Canvas canvas, Offset center, double r, int sides, Paint p) {
    final path = Path();
    final double angle = (2 * pi) / sides;
    Offset start = Offset(center.dx + r * cos(-pi / 2), center.dy + r * sin(-pi / 2));

    path.moveTo(start.dx, start.dy);

    for (int i = 1; i <= sides; i++) {
      double x = center.dx + r * cos(angle * i - pi / 2);
      double y = center.dy + r * sin(angle * i - pi / 2);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, p);
  }
}
