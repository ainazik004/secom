// lib/pages/mock_test/mock_test_start_page.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';
import 'package:zhalbyrak/l10n/l10n_ext.dart';
import 'package:zhalbyrak/currency/paid_confirm_dialog.dart';
import '../../widgets/quiz_runner/widgets/round_x_button.dart';

// ✅ Currency
import 'package:zhalbyrak/currency/currency_gate.dart';
import '../mock_attempt_store.dart';
import '../mock_test_controller.dart';
import 'mock_test_runner_page.dart';

// MUST match Firestore pricing key
const String kActionMockTestStart = 'start_mock_test';

class MockTestStartPage extends StatefulWidget {
  final String lang; // ru/ky/en
  const MockTestStartPage({super.key, required this.lang});

  @override
  State<MockTestStartPage> createState() => _MockTestStartPageState();
}

class _MockTestStartPageState extends State<MockTestStartPage> {
  late final MockTestController controller;
  bool loading = true;

  // ✅ prevent double-taps / multi-start
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    controller = MockTestController(
      db: FirebaseFirestore.instance,
      store: MockAttemptStore(),
    );

    () async {
      await controller.restore();
      if (!mounted) return;
      setState(() => loading = false);
    }();
  }

  // ✅ re-check attempt after coming back from runner
  Future<void> _refreshAttempt() async {
    await controller.restore();
    if (!mounted) return;
    setState(() {});
  }

  String _idempotencyKey() => 'mock_${DateTime.now().microsecondsSinceEpoch}';

  Future<bool> _confirmSpend(BuildContext context, int cost) async {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(loc.paidActionTitle),
        content: Text(
          '${loc.confirmActionBodyPrefix}${loc.mock_start_new}.\n\n'
              '${loc.confirmActionCost}: ${loc.zhalbyrakCount(cost)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.paidActionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: cs.primary),
            child: Text(loc.paidActionProceed),
          ),
        ],
      ),
    ) ??
        false;
  }

  // ✅ Paid flow for "Start new" (with idempotency + spend)
  Future<void> _startPaidNew() async {
    if (_starting) return;

    final gate = context.read<CurrencyGate>();

    // ✅ Fast local check BEFORE showing confirm
    if (!gate.canAffordNow(kActionMockTestStart)) {
      await gate.showNotEnoughPaywall(
        context,
        actionKey: kActionMockTestStart,
      );
      return;
    }

    final cost = gate.costOf(kActionMockTestStart);

    final ok = await PaidConfirmDialog.show(
      context,
      cost: cost,
    );
    if (!ok) return;

    setState(() => _starting = true);

    try {
      await gate.spend(
        actionKey: kActionMockTestStart,
        ref: 'mock_start',
        idempotencyKey: _idempotencyKey(),
      );

      await controller.restore();

      final a = controller.attempt;
      final hasActive = a != null && !a.isFinished;
      if (!hasActive) {
        await controller.startNew(lang: widget.lang);
      }

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MockTestRunnerPage(controller: controller),
        ),
      );

      await _refreshAttempt();
    } on FirebaseFunctionsException catch (e) {
      // ✅ Server remains authoritative
      if (e.code == 'failed-precondition' && e.message == 'NOT_ENOUGH_ZHALBYRAKS') {
        await gate.showNotEnoughPaywall(context, actionKey: kActionMockTestStart);
        return;
      }
      rethrow;
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  // ✅ Continue flow (NO spending). Uses controller logic from file #1.
  Future<void> _continueAndOpenRunner() async {
    if (_starting) return;
    setState(() => _starting = true);

    try {
      await controller.restore();
      await controller.startCurrentSectionIfNeeded();

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MockTestRunnerPage(controller: controller),
        ),
      );

      await _refreshAttempt();
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.mock_setup_required_title),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _discardCurrent() async {
    if (_starting) return;

    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final sure = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(loc.mock_discard_title),
        content: Text(loc.mock_discard_desc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: cs.error),
            child: Text(loc.discard),
          ),
        ],
      ),
    );

    if (sure != true) return;

    setState(() => _starting = true);
    try {
      await controller.clearAttempt();
      if (!mounted) return;
      setState(() {});
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final gate = context.watch<CurrencyGate>();
    final cost = gate.costOf(kActionMockTestStart);

    final attempt = controller.attempt;

    final pageBg = cs.surface;
    final cardBg = isDark ? cs.surfaceContainerHighest : cs.surfaceContainerHigh;

    final costBg = isDark
        ? const Color(0xFF0B2A16) // deep green
        : const Color(0xFFE7F7EE); // light green

    final leafColor = isDark
        ? const Color(0xFF2FBF71) // darker, calmer green for dark mode
        : const Color(0xFF1E9E55); // clean green for light mode

    final shadow = BoxShadow(
      color: cs.shadow.withOpacity(isDark ? 0.35 : 0.12),
      blurRadius: isDark ? 20 : 18,
      offset: const Offset(0, 10),
    );

    Widget card({required Widget child}) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [shadow],
        ),
        child: child,
      );
    }

    if (loading) {
      return Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          backgroundColor: pageBg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: RoundXButton(onTap: () => Navigator.of(context).pop()),
          ),
          title: Text(
            loc.mock_title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(color: cs.primary),
        ),
      );
    }

    final hasActive = attempt != null && !attempt.isFinished;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: RoundXButton(onTap: () => Navigator.of(context).pop()),
        ),
        title: Text(
          loc.mock_title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: cs.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [
          // Hero / Info (✅ progress line removed)
          card(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.assignment_rounded,
                    color: cs.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.mock_hero_title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        loc.mock_hero_desc,
                        style: TextStyle(
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant.withOpacity(0.88),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Mock overview
          card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.mock_overview_title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.layers_rounded,
                  title: loc.mock_sections_title,
                  value: loc.mock_sections_value,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.route_rounded,
                  title: loc.mock_order_title,
                  value: loc.mock_order_value,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.timer_rounded,
                  title: loc.mock_time_title,
                  value: loc.mock_time_value,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tips / Rules
          card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.mock_tips_title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                _Bullet(loc.mock_tip_1),
                _Bullet(loc.mock_tip_2),
                _Bullet(loc.mock_tip_3),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // CTA buttons (design from file #1, functions/content from file #2)
          if (hasActive) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _starting ? null : _continueAndOpenRunner, // ✅ no spend
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  disabledBackgroundColor: cs.primary.withOpacity(0.35),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _starting
                    ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: cs.onPrimary,
                  ),
                )
                    : Text(
                  loc.mock_continue,
                  style: TextStyle(fontWeight: FontWeight.w900, color: cs.onPrimary),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _starting ? null : _discardCurrent,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: BorderSide(color: cs.error.withOpacity(0.40)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  loc.mock_discard,
                  style: TextStyle(fontWeight: FontWeight.w900, color: cs.error),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _starting ? null : _startPaidNew,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  disabledBackgroundColor: cs.primary.withOpacity(0.35),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _starting
                    ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: cs.onPrimary,
                  ),
                )
                    : Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: loc.mock_start_new),
                      const TextSpan(text: '  '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(
                          Icons.eco_rounded,
                          size: 16,
                          color: leafColor, // already darker in dark mode
                        ),
                      ),
                      TextSpan(
                        text: ' $cost',
                        style: TextStyle(
                          color: leafColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: cs.onPrimary,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),
          const SafeArea(top: false, child: SizedBox()),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(isDark ? 0.16 : 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: cs.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant.withOpacity(0.88),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
              height: 1.35,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant.withOpacity(0.88),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
