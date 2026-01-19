import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/z_theme.dart';

class PercentDonut extends StatelessWidget {
  final int percent;
  final double size;
  final double stroke;

  const PercentDonut({
    super.key,
    required this.percent,
    required this.size,
    required this.stroke,
  });

  @override
  Widget build(BuildContext context) {
    final p = (percent.clamp(0, 100)) / 100.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _DonutPainter(
              value: p,
              stroke: stroke,
              background: const Color(0xFFEAE7FF),
              foreground: ZTheme.purple,
            ),
          ),
          Container(
            padding: const EdgeInsets.only(top: 2),
            alignment: Alignment.center,
            child: Text(
              '$percent%',
              style: const TextStyle(
                fontSize: 32,
                height: 1.0,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double value;
  final double stroke;
  final Color background;
  final Color foreground;

  _DonutPainter({
    required this.value,
    required this.stroke,
    required this.background,
    required this.foreground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide / 2) - (stroke / 2);

    final bgPaint = Paint()
      ..color = background
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi,
      false,
      bgPaint,
    );

    final sweep = (2 * pi) * value.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweep,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.stroke != stroke ||
        oldDelegate.background != background ||
        oldDelegate.foreground != foreground;
  }
}
