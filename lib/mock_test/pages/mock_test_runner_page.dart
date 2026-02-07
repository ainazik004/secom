// mock_test_runner_page.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';

import '../../widgets/quiz_runner/widgets/comparison_value_card.dart';
import '../../widgets/quiz_runner/widgets/round_x_button.dart';
import '../mock_models.dart';
import '../mock_test_controller.dart';
import 'mock_test_overview_page.dart';

class MockTestRunnerPage extends StatefulWidget {
  final MockTestController controller;
  const MockTestRunnerPage({super.key, required this.controller});

  @override
  State<MockTestRunnerPage> createState() => _MockTestRunnerPageState();
}

class _MockTestRunnerPageState extends State<MockTestRunnerPage> {
  bool _loading = true;
  bool _submitting = false;

  // ✅ initialize (avoid late-init issues)
  List<_QDoc> _qs = const [];

  // ✅ rebuild timer label every second
  Timer? _uiTick;

  @override
  void initState() {
    super.initState();
    _startUiTick();
    _loadCurrentSection();
  }

  @override
  void dispose() {
    _uiTick?.cancel();
    super.dispose();
  }

  void _startUiTick() {
    _uiTick?.cancel();

    // Initial refresh so label is correct immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
    });

    _uiTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      // Optional: reduce rebuilds when not needed.
      // If your controller can tell "time is running", keep this.
      // Otherwise it still works as-is.
      setState(() {});
    });
  }

  Future<void> _loadCurrentSection() async {
    setState(() => _loading = true);

    final a = widget.controller.attempt;
    if (a == null) {
      if (!mounted) return;
      setState(() {
        _qs = const [];
        _loading = false;
      });
      return;
    }

    final refs = widget.controller.currentSectionRefs;

    // Fetch all docs in parallel
    final futures = refs.map((r) async {
      final snap = await FirebaseFirestore.instance
          .collection('questions')
          .doc(r.lang)
          .collection(r.section)
          .doc(r.id)
          .get();

      final data = snap.data() ?? <String, dynamic>{};
      return _QDoc(ref: r, data: data);
    });

    final res = await Future.wait(futures);

    if (!mounted) return;
    setState(() {
      _qs = res;
      _loading = false;
    });
  }

  bool _isComparison(Map<String, dynamic> d) {
    final t = (d['topic'] ?? '').toString().toLowerCase();
    return t == 'comparison' || t.startsWith('comparison/') || t.contains('/comparison');
  }

  String _cleanStem(String stem) {
    var s = stem.trim();

    s = s.replaceAll('Сравните значения', '').trim();
    s = s.replaceAll('Сравните значения:', '').trim();
    s = s.replaceAll('Compare values', '').trim();
    s = s.replaceAll('Compare values:', '').trim();

    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    s = s.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    s = s.trim();

    final onlyPunct = s.replaceAll(RegExp(r'[\s\.\u2022•·-]+'), '');
    if (onlyPunct.isEmpty) return '';
    return s;
  }

  List<String> _optionKeys(Map<String, dynamic> d) {
    final opts = d['options'];
    if (opts is Map) {
      final keys = opts.keys.map((e) => e.toString()).toList()..sort();
      return keys;
    }
    return const ['A', 'B', 'C', 'D', 'E'];
  }

  String _optText(Map<String, dynamic> d, String key) {
    final opts = d['options'];
    if (opts is Map && opts[key] != null) return opts[key].toString();
    return '';
  }

  Future<void> _submitSection() async {
    if (_submitting) return;

    setState(() => _submitting = true);
    try {
      await widget.controller.submitCurrentSection();
      if (!mounted) return;

      if (widget.controller.attempt?.isFinished == true) {
        _uiTick?.cancel();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MockTestOverviewPage(controller: widget.controller),
          ),
        );
        return;
      }

      await _loadCurrentSection();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pageBg = cs.surface;
    final cardBg = isDark ? cs.surfaceContainerHighest : cs.surfaceContainerHigh;

    final shadow = BoxShadow(
      color: cs.shadow.withOpacity(isDark ? 0.35 : 0.12),
      blurRadius: isDark ? 20 : 18,
      offset: const Offset(0, 10),
    );

    final sec = widget.controller.currentSectionType;
    final secTitle = sec == null ? '—' : widget.controller.sectionTitle(loc, sec);

    // time label updates due to periodic setState()
    final timeLabel = widget.controller.timeLeftLabel();

    if (_loading) {
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
            secTitle,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: cs.onSurface),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: _TimerChip(label: timeLabel, cs: cs, isDark: isDark),
              ),
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final answered = _qs.where((q) => (widget.controller.getPicked(q.ref) ?? '').isNotEmpty).length;
    final total = _qs.length;

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              secTitle,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: cs.onSurface),
            ),
            Text(
              loc.quiz_progress(answered, total),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant.withOpacity(0.75),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: _TimerChip(label: timeLabel, cs: cs, isDark: isDark),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        itemCount: _qs.length + 1,
        itemBuilder: (context, i) {
          if (i == _qs.length) {
            return Column(
              children: [
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submitSection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      disabledBackgroundColor: cs.primary.withOpacity(0.35),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _submitting ? loc.sending : loc.submit_section,
                      style: TextStyle(fontWeight: FontWeight.w900, color: cs.onPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const SafeArea(top: false, child: SizedBox()),
              ],
            );
          }

          final q = _qs[i];
          final d = q.data;

          final picked = widget.controller.getPicked(q.ref) ?? '';
          final stem = _cleanStem((d['stem'] ?? '').toString());
          final isComp = _isComparison(d);

          final left = (d['left'] ?? '').toString().trim();
          final right = (d['right'] ?? '').toString().trim();

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [shadow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(isDark ? 0.16 : 0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Q${i + 1}',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: cs.primary),
                        ),
                      ),
                      const Spacer(),
                      if (picked.isNotEmpty) Icon(Icons.check_circle_rounded, size: 18, color: cs.primary),
                    ],
                  ),
                  if (stem.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      stem,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.35,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (isComp) ...[
                    Row(
                      children: [
                        Expanded(child: ComparisonSideCard(value: left.isEmpty ? '—' : left, cs: cs)),
                        const SizedBox(width: 12),
                        Expanded(child: ComparisonSideCard(value: right.isEmpty ? '—' : right, cs: cs)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _CompPickTile(
                                letter: 'A',
                                picked: picked,
                                cs: cs,
                                onTap: () async {
                                  await widget.controller.selectAnswer(q.ref, 'A');
                                  if (mounted) setState(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CompPickTile(
                                letter: 'B',
                                picked: picked,
                                cs: cs,
                                onTap: () async {
                                  await widget.controller.selectAnswer(q.ref, 'B');
                                  if (mounted) setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _CompPickTile(
                                letter: 'C',
                                picked: picked,
                                cs: cs,
                                onTap: () async {
                                  await widget.controller.selectAnswer(q.ref, 'C');
                                  if (mounted) setState(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CompPickTile(
                                letter: 'D',
                                picked: picked,
                                cs: cs,
                                onTap: () async {
                                  await widget.controller.selectAnswer(q.ref, 'D');
                                  if (mounted) setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ] else ...[
                    ..._optionKeys(d)
                        .map((k) {
                      final text = _optText(d, k);
                      if (text.trim().isEmpty) return const SizedBox.shrink();

                      final isPicked = picked == k;
                      final fill = isPicked
                          ? Color.alphaBlend(cs.primary.withOpacity(isDark ? 0.16 : 0.10), cardBg)
                          : cardBg;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            await widget.controller.selectAnswer(q.ref, k);
                            if (mounted) setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: fill,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [shadow],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: cs.surface.withOpacity(isDark ? 0.50 : 0.85),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    k,
                                    style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    text,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.35,
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    })
                        .whereType<Widget>(),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TimerChip extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  final bool isDark;

  const _TimerChip({
    required this.label,
    required this.cs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w900, color: cs.primary),
      ),
    );
  }
}

class _QDoc {
  final QuestionRef ref;
  final Map<String, dynamic> data;
  _QDoc({required this.ref, required this.data});
}

class _CompPickTile extends StatelessWidget {
  final String letter;
  final String picked;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _CompPickTile({
    required this.letter,
    required this.picked,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPickedTile = letter == picked;

    final fill = isPickedTile
        ? Color.alphaBlend(cs.primary.withOpacity(isDark ? 0.18 : 0.12), cs.surfaceContainerHighest)
        : cs.surfaceContainerHighest;

    final shadow = [
      BoxShadow(
        color: cs.shadow.withOpacity(isDark ? 0.14 : 0.10),
        blurRadius: 14,
        offset: const Offset(0, 10),
      ),
    ];

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        height: 72,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(18),
            boxShadow: shadow,
          ),
          child: Center(
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: isPickedTile ? cs.primary : cs.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
