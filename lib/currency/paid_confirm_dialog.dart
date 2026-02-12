import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../gen_l10n/app_localizations.dart';

class PaidConfirmDialog {
  static Future<bool> show(
      BuildContext context, {
        required int cost,
      }) async {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final costFormatted =
    NumberFormat.decimalPattern(loc.localeName).format(cost);
    final unit = loc.currencyUnit(cost);

    final leafColor = isDark
        ? const Color(0xFF2FBF71)
        : const Color(0xFF1E9E55);

    final cardBg =
    isDark ? cs.surfaceContainerHighest : cs.surfaceContainerHigh;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withOpacity(isDark ? 0.35 : 0.14),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          loc.confirmActionTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.pop(context, false),
                        icon: Icon(Icons.close_rounded, color: cs.onSurface),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                    loc.confirmActionBodyPrefix,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant.withOpacity(0.90),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 🌿 Cost (centered)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.eco_rounded, size: 18, color: leafColor),
                      const SizedBox(width: 6),
                      Text(
                        '$costFormatted $unit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: leafColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 🧠 Hungry Jinny — NO background
                  Image.asset(
                    'assets/hungry_jinny.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 18),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(
                              color: cs.outline
                                  .withOpacity(isDark ? 0.35 : 0.45),
                            ),
                          ),
                          child: Text(
                            loc.paidActionCancel,
                            style:
                            const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            padding:
                            const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            loc.paidActionProceed,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: cs.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return result == true;
  }
}
