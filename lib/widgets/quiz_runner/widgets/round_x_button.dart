import 'package:flutter/material.dart';

class RoundXButton extends StatelessWidget {
  final VoidCallback onTap;
  const RoundXButton({super.key, required this.onTap});

  static const double _size = 36;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: cs.surfaceContainerHighest,
      shape: const CircleBorder(),
      elevation: 0,
      shadowColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        splashColor: cs.primary.withOpacity(0.12),
        highlightColor: cs.primary.withOpacity(0.08),
        child: SizedBox(
          width: _size,
          height: _size,
          child: Center(
            child: Icon(
              Icons.close_rounded,
              size: 18,
              color: cs.onSurface.withOpacity(isDark ? 0.85 : 0.70),
            ),
          ),
        ),
      ),
    );
  }
}
