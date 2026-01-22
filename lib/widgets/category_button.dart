import 'package:flutter/material.dart';

class CategoryButton extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? accentColor;
  final Widget page;

  const CategoryButton({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.accentColor,
    required this.page,
  });

  @override
  State<CategoryButton> createState() => _CategoryButtonState();
}

class _CategoryButtonState extends State<CategoryButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails _) => setState(() => _scale = 0.985);
  void _onTapUp(TapUpDetails _) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final isDark = cs.brightness == Brightness.dark;

    // Card surface like the screenshot
    final cardBg = cs.surfaceContainerHighest;
    final border = cs.outlineVariant.withOpacity(isDark ? 0.55 : 0.75);

    // Soft shadow like the screenshot
    final shadow = cs.shadow.withOpacity(isDark ? 0.22 : 0.10);

    // Accent for icon bubble
    final accent = widget.accentColor ?? cs.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Material(
          color: cardBg,
          surfaceTintColor: Colors.transparent, // avoid Material3 tint “wash”
          borderRadius: BorderRadius.circular(26),
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => widget.page),
              );
            },
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            child: Container(
              height: 108,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: shadow,
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Left icon bubble
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(isDark ? 0.22 : 0.16),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: cs.outlineVariant.withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      color: accent,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Title + subtitle
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        if ((widget.subtitle ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant.withOpacity(0.75),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Right chevron
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 30,
                    color: cs.onSurfaceVariant.withOpacity(0.45),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
