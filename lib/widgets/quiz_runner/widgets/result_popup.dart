import 'package:flutter/material.dart';
import '../theme/z_theme.dart';
import 'percent_donut.dart';
import 'stat_tile.dart';

class ResultPopup extends StatelessWidget {
  final String title;
  final String brand;
  final int percent;
  final String correctText;

  final String trophiesLabel;
  final String trophiesCount;

  final String totalLabel;
  final String totalCount;

  final String reviewText;
  final String closeText;
  final String retryText;

  final VoidCallback onReview;
  final VoidCallback onClose;
  final VoidCallback onRetry;

  const ResultPopup({
    super.key,
    required this.title,
    required this.brand,
    required this.percent,
    required this.correctText,
    required this.trophiesLabel,
    required this.trophiesCount,
    required this.totalLabel,
    required this.totalCount,
    required this.reviewText,
    required this.closeText,
    required this.retryText,
    required this.onReview,
    required this.onClose,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ Match HomePage gradient in DARK mode only (light mode stays as before)
    // Replace these with the exact colors you use on HomePage dark gradient if different.
    const darkHomeGradA = Color(0xFF2C015D);
    const darkHomeGradB = Color(0xFF12012B);

    final headerGradient = isDark
        ? const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [darkHomeGradA, darkHomeGradB],
    )
        : const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFF4D8D),
        Color(0xFF7C3AED),
      ],
    );

    // ✅ Popup surfaces: stay lighter than bg in dark mode
    final popupSurface = isDark ? cs.surfaceContainerHighest : cs.surface;
    final innerPanel =
    isDark ? cs.surfaceContainerHigh : cs.surfaceContainerHighest;

    final subtleStroke = cs.outlineVariant.withOpacity(isDark ? 0.22 : 0.35);
    final shadowColor = cs.shadow.withOpacity(isDark ? 0.50 : 0.18);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            blurRadius: 28,
            offset: const Offset(0, 14),
            color: shadowColor,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---------- Header (Dark mode uses HomePage gradient) ----------
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(gradient: headerGradient),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.20)),
                    ),
                    child: const Icon(
                      Icons.emoji_events_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ---------- Body ----------
            Container(
              color: popupSurface,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: innerPanel,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: subtleStroke),
                    ),
                    child: Row(
                      children: [
                        PercentDonut(percent: percent, size: 132, stroke: 14),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                brand,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color:
                                  cs.onSurfaceVariant.withOpacity(0.85),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                correctText,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  height: 1.2,
                                  color: cs.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          label: trophiesLabel,
                          value: trophiesCount,
                          icon: Icons.emoji_events_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatTile(
                          label: totalLabel,
                          value: totalCount,
                          icon: Icons.list_alt_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: onReview,
                          style: TextButton.styleFrom(
                            foregroundColor: cs.primary,
                          ),
                          child: Text(
                            reviewText,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onClose,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: isDark ? 0 : 1,
                          ),
                          child: Text(
                            closeText,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onRetry,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: cs.primary.withOpacity(0.35)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: cs.primary,
                      ),
                      child: Text(
                        retryText,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
