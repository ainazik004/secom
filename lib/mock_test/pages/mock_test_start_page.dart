import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';

import '../mock_attempt_store.dart';
import '../mock_test_controller.dart';
import 'mock_test_runner_page.dart';

class MockTestStartPage extends StatefulWidget {
  final String lang; // from settings/provider (ru/ky/en)
  const MockTestStartPage({super.key, required this.lang});

  @override
  State<MockTestStartPage> createState() => _MockTestStartPageState();
}

class _MockTestStartPageState extends State<MockTestStartPage> {
  late final MockTestController controller;
  bool loading = true;

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

  Future<void> _startAndOpenRunner({required bool startNew}) async {
    try {
      if (startNew) {
        await controller.startNew(lang: widget.lang);
      } else {
        await controller.startCurrentSectionIfNeeded();
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MockTestRunnerPage(controller: controller),
        ),
      );
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
    }
  }

  Future<void> _discardCurrent() async {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final sure = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
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

    await controller.clearAttempt();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final attempt = controller.attempt;

    final pageBg = cs.surface;
    final cardBg = isDark ? cs.surfaceContainerHighest : cs.surfaceContainerHigh;

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

    // Best-effort progress info (works even if your attempt model changes)
    final sectionsTotal = 5;
    int answered = 0;
    int total = 0;

    try {
      // Common shapes people use:
      // - attempt.answers : Map<String, dynamic>
      // - attempt.answersByIndex : Map<int, String>
      // - attempt.totalQuestions : int
      // If none exist, these keep defaults.
      final dynamic a = attempt;
      final dynamic answers =
      (a == null) ? null : (a.answers ?? a.answersByIndex ?? a.userAnswers);
      if (answers is Map) {
        total = a.totalQuestions is int ? a.totalQuestions as int : 0;
        answered = answers.values.where((v) => (v ?? '').toString().trim().isNotEmpty).length;
      } else if (answers is List) {
        total = a.totalQuestions is int ? a.totalQuestions as int : answers.length;
        answered = answers.where((v) => (v ?? '').toString().trim().isNotEmpty).length;
      }
    } catch (_) {
      // ignore
    }

    final String progressLine;
    if (!hasActive) {
      progressLine = loc.mock_no_active_progress;
    } else {
      // If total is unknown, still show answered count.
      progressLine = total > 0
          ? loc.mock_progress(answered, total)
          : loc.mock_progress_unknown_total(answered);
    }

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
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
          // Hero / Info
          card(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // icon badge
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
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: cs.surface.withOpacity(isDark ? 0.18 : 0.60),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
                        ),
                        child: Text(
                          progressLine,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: cs.onSurface,
                          ),
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

          // CTA buttons
          if (hasActive) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _startAndOpenRunner(startNew: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  loc.mock_continue,
                  style: TextStyle(fontWeight: FontWeight.w900, color: cs.onPrimary),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _discardCurrent,
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
                onPressed: () => _startAndOpenRunner(startNew: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  loc.mock_start_new,
                  style: TextStyle(fontWeight: FontWeight.w900, color: cs.onPrimary),
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
