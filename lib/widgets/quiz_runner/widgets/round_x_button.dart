import 'package:flutter/material.dart';
import '../theme/z_theme.dart';

class RoundXButton extends StatelessWidget {
  final VoidCallback onTap;
  const RoundXButton({super.key, required this.onTap});

  static const double _size = 36;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ZTheme.pillBg,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: _size,
          height: _size,
          child: Center(
            child: Icon(
              Icons.close,
              size: 18,
              color: Colors.black.withOpacity(0.75),
            ),
          ),
        ),
      ),
    );
  }
}
