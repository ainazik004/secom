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

class _MockTestRunnerPageState extends State<MockTestRunnerPage>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _submitting = false;

  // ✅ initialize (avoid late-init issues)
  List<_QDoc> _qs = const [];

  // ✅ rebuild timer label every second
  Timer? _uiTick;

  // ✅ show overlay as soon as paused
  bool _pauseOverlayVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startUiTick();
    _loadCurrentSection();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _uiTick?.cancel();
    super.dispose();
  }

  void _startUiTick() {
    _uiTick?.cancel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
    });

    _uiTick = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;

      // Keeps timeouts correct when not paused
      await widget.controller.tick();

      // Track pause overlay state
      final paused = widget.controller.isPaused;
      if (paused != _pauseOverlayVisible) {
        _pauseOverlayVisible = paused;
      }

      setState(() {});
    });
  }

  // ✅ Auto-pause on background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      await _pauseAndShowOverlay();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      // Do not auto-resume; user must press Resume on overlay.
      if (mounted) setState(() {});
    }
  }

  Future<void> _pauseAndShowOverlay() async {
    await widget.controller.pause();
    if (!mounted) return;
    setState(() => _pauseOverlayVisible = true);
  }

  Future<void> _resumeAndHideOverlay() async {
    await widget.controller.resume();
    if (!mounted) return;
    setState(() => _pauseOverlayVisible = false);
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

      // Respect persisted pause on restore
      _pauseOverlayVisible = widget.controller.isPaused;
    });
  }

  bool _isComparison(Map<String, dynamic> d) {
    final t = (d['topic'] ?? '').toString().toLowerCase();
    return t == 'comparison' ||
        t.startsWith('comparison/') ||
        t.contains('/comparison');
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

  Future<void> _confirmExit() async {
    final loc = AppLocalizations.of(context)!;

    await _pauseAndShowOverlay();
    if (!mounted) return;

    final cs = Theme.of(context).colorScheme;

    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(loc.exit),
        content: Text(loc.test_paused_exit_confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.exit),
          ),
        ],
      ),
    );

    if (res == true && mounted) {
      Navigator.of(context).pop();
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
    final secTitle =
    sec == null ? '—' : widget.controller.sectionTitle(loc, sec);

    final timeLabel = widget.controller.timeLeftLabel();
    final paused = _pauseOverlayVisible || widget.controller.isPaused;

    // ✅ Disable scrolling when paused by switching physics
    final scrollPhysics =
    paused ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics();

    final answered =
        _qs.where((q) => (widget.controller.getPicked(q.ref) ?? '').isNotEmpty).length;
    final total = _qs.length;

    return WillPopScope(
      onWillPop: () async {
        await _confirmExit();
        return false;
      },
      child: Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          backgroundColor: pageBg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: RoundXButton(onTap: _confirmExit),
          ),
          title: _loading
              ? Text(
            secTitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ),
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                secTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                ),
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
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: _TimerChip(label: timeLabel, cs: cs, isDark: isDark),
              ),
            ),
            IconButton(
              tooltip: paused ? loc.resume : loc.pause,
              onPressed: () async {
                if (paused) {
                  await _resumeAndHideOverlay();
                } else {
                  await _pauseAndShowOverlay();
                }
              },
              icon: Icon(paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: Stack(
          children: [
            // CONTENT
            AbsorbPointer(
              absorbing: paused, // ✅ blocks taps while paused
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                physics: scrollPhysics,
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
                            onPressed: (_submitting || paused)
                                ? null
                                : _submitSection,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cs.primary,
                              disabledBackgroundColor:
                              cs.primary.withOpacity(0.35),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              _submitting ? loc.sending : loc.submit_section,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: cs.onPrimary,
                              ),
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

                  final picked =
                      widget.controller.getPicked(q.ref) ?? '';
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: cs.primary.withOpacity(
                                      isDark ? 0.16 : 0.10),
                                  borderRadius:
                                  BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Q${i + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    color: cs.primary,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (picked.isNotEmpty)
                                Icon(Icons.check_circle_rounded,
                                    size: 18, color: cs.primary),
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
                                Expanded(
                                  child: ComparisonSideCard(
                                    value: left.isEmpty ? '—' : left,
                                    cs: cs,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ComparisonSideCard(
                                    value: right.isEmpty ? '—' : right,
                                    cs: cs,
                                  ),
                                ),
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
                                          await widget.controller
                                              .selectAnswer(q.ref, 'A');
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
                                          await widget.controller
                                              .selectAnswer(q.ref, 'B');
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
                                          await widget.controller
                                              .selectAnswer(q.ref, 'C');
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
                                          await widget.controller
                                              .selectAnswer(q.ref, 'D');
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
                              if (text.trim().isEmpty) {
                                return const SizedBox.shrink();
                              }

                              final isPicked = picked == k;
                              final fill = isPicked
                                  ? Color.alphaBlend(
                                cs.primary.withOpacity(
                                    isDark ? 0.16 : 0.10),
                                cardBg,
                              )
                                  : cardBg;

                              return Padding(
                                padding:
                                const EdgeInsets.only(bottom: 10),
                                child: InkWell(
                                  borderRadius:
                                  BorderRadius.circular(16),
                                  onTap: () async {
                                    await widget.controller
                                        .selectAnswer(q.ref, k);
                                    if (mounted) setState(() {});
                                  },
                                  child: Container(
                                    padding:
                                    const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: fill,
                                      borderRadius:
                                      BorderRadius.circular(16),
                                      boxShadow: [shadow],
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 30,
                                          height: 30,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: cs.surface
                                                .withOpacity(isDark
                                                ? 0.50
                                                : 0.85),
                                            borderRadius:
                                            BorderRadius.circular(
                                                12),
                                          ),
                                          child: Text(
                                            k,
                                            style: TextStyle(
                                              fontWeight:
                                              FontWeight.w900,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            text,
                                            style: TextStyle(
                                              fontSize: 14,
                                              height: 1.35,
                                              fontWeight:
                                              FontWeight.w700,
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
            ),

            // ✅ PAUSE OVERLAY
            if (paused)
              _PauseOverlay(
                title: loc.test_paused_title,
                subtitle: loc.test_paused_subtitle,
                resumeLabel: loc.resume,
                exitLabel: loc.exit,
                onResume: _resumeAndHideOverlay,
                onExit: () async {
                  // Keep paused and exit
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
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
        ? Color.alphaBlend(
      cs.primary.withOpacity(isDark ? 0.18 : 0.12),
      cs.surfaceContainerHighest,
    )
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

/// Full-screen pause overlay that matches the app's card style.
class _PauseOverlay extends StatelessWidget {
  final String title;
  final String subtitle;
  final String resumeLabel;
  final String exitLabel;
  final VoidCallback onResume;
  final VoidCallback onExit;

  const _PauseOverlay({
    required this.title,
    required this.subtitle,
    required this.resumeLabel,
    required this.exitLabel,
    required this.onResume,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final overlay = isDark
        ? Colors.black.withOpacity(0.55)
        : Colors.black.withOpacity(0.40);

    final cardBg = isDark ? cs.surfaceContainerHighest : cs.surface;

    final shadow = BoxShadow(
      color: cs.shadow.withOpacity(isDark ? 0.35 : 0.18),
      blurRadius: 26,
      offset: const Offset(0, 14),
    );

    return Positioned.fill(
      child: Material(
        color: overlay,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [shadow],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // top pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(isDark ? 0.16 : 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pause_circle_filled_rounded, size: 18, color: cs.primary),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant.withOpacity(0.90),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onExit,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: cs.outline.withOpacity(0.25)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              exitLabel,
                              style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onResume,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cs.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              resumeLabel,
                              style: TextStyle(fontWeight: FontWeight.w900, color: cs.onPrimary),
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
      ),
    );
  }
}
