import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../gen_l10n/app_localizations.dart';
import 'paywall_models.dart';

class PaywallSheet {
  static Future<void> show(
      BuildContext context, {
        required PaywallRequest request,
        required VoidCallback onSubscribe,
        required VoidCallback onDonate,
      }) async {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final green = isDark
        ? const Color(0xFF2FBF71)
        : const Color(0xFF1E9E55);

    final costFormatted =
    NumberFormat.decimalPattern(loc.localeName).format(request.cost);

    final currencyText = loc.currencyUnit(request.cost);

    // ✅ LOCALIZED title: "Недостаточно ЖАЛБЫРАКОВ"
    final title = loc.paywall_notEnoughTitle(currencyText);

    final cardBg =
    isDark ? cs.surfaceContainerHighest : cs.surfaceContainerHigh;

    await showDialog<void>(
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
                          title,
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
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: cs.onSurface),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Message
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: cs.onSurfaceVariant.withOpacity(0.90),
                      ),
                      children: [
                        TextSpan(text: loc.confirmActionCost + ' '),
                        TextSpan(
                          text: '$costFormatted $currencyText',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: green,
                          ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Confused Jinny (transparent background)
                  Image.asset(
                    'assets/confused_jinny.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 18),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onSubscribe();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      loc.paywall_subscribe,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),

                  const SizedBox(height: 10),

                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onDonate();
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(
                        color: cs.outline.withOpacity(isDark ? 0.35 : 0.45),
                      ),
                    ),
                    child: Text(
                      loc.paywall_donate,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      loc.paywall_cancel,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
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
