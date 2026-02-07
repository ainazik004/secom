// lib/mock_test/pages/mock_test_overview_page.dart
import 'package:flutter/material.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';

import '../../widgets/quiz_runner/widgets/round_x_button.dart';

import '../mock_question_loader.dart';
import '../mock_test_controller.dart';
import '../mock_question_loader.dart' show MockQuestion; // safe explicit
import 'mock_single_review_page.dart';

class MockTestOverviewPage extends StatefulWidget {
  final MockTestController controller;
  const MockTestOverviewPage({super.key, required this.controller});

  @override
  State<MockTestOverviewPage> createState() => _MockTestOverviewPageState();
}

class _MockTestOverviewPageState extends State<MockTestOverviewPage> {
  late final MockQuestionLoader loader;
  bool loading = true;

  final List<_SectionGroup> groups = [];

  @override
  void initState() {
    super.initState();
    loader = MockQuestionLoader(widget.controller.db);

    () async {
      await widget.controller.restore();
      await _buildGroups();
      if (mounted) setState(() => loading = false);
    }();
  }

  Future<void> _buildGroups() async {
    final a = widget.controller.attempt;
    if (a == null) return;

    groups.clear();

    int globalNumber = 0;
    int sectionIndex = 0;

    // ✅ No section getter: categories are the attempt.sections boundaries.
    for (final s in a.sections) {
      sectionIndex += 1;

      final questions = <MockQuestion>[];
      final answers = <int, String>{};
      final tiles = <_OverviewTile>[];

      int localIndex = 0;

      for (final ref in s.questions) {
        final q = await loader.loadOne(ref);
        final user = a.answers[ref.key()];

        if (user != null) answers[localIndex] = user;

        final correct = q.correct;
        final isCorrect = (user != null && user == correct && correct.isNotEmpty);

        globalNumber += 1;

        questions.add(q);
        tiles.add(
          _OverviewTile(
            globalNumber: globalNumber,
            localIndex: localIndex,
            context: _previewTextForTile(q),
            userAnswer: user,
            isCorrect: isCorrect,
          ),
        );

        localIndex += 1;
      }

      if (questions.isEmpty) continue;

      groups.add(
        _SectionGroup(
          sectionIndex: sectionIndex,
          questions: questions,
          answers: answers,
          tiles: tiles,
        ),
      );
    }
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  // ✅ Localized header per category (based on section order).
  // Adjust order if your mock attempt.sections order differs.
  String _categoryTitle(AppLocalizations loc, int sectionIndex) {
    switch (sectionIndex) {
      case 1:
        return loc.math;
      case 2:
        return loc.analogy;
      case 3:
        return loc.reading;
      case 4:
        return loc.grammar;
      default:
        return 'Category $sectionIndex';
    }
  }

  // ---------- Context preview (same logic as your grid pages) ----------

  bool _isComparison(MockQuestion q) => q.isComparison;

  String _cleanStem(String stem) {
    var s = stem.trim();
    s = s.replaceAll('Сравните значения', '').trim();
    s = s.replaceAll('Сравните значения:', '').trim();
    s = s.replaceAll('Compare values', '').trim();
    s = s.replaceAll('Compare values:', '').trim();
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    s = s.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    return s;
  }

  String _previewTextForTile(MockQuestion q) {
    if (_isComparison(q)) {
      final l = q.left.trim();
      final r = q.right.trim();
      if (l.isNotEmpty || r.isNotEmpty) {
        final left = l.isEmpty ? '—' : l;
        final right = r.isEmpty ? '—' : r;
        return '$left  vs  $right';
      }
    }
    final s = _cleanStem(q.stem);
    return s.isEmpty ? '—' : s;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pageBg = cs.surface;
    final tileBg = isDark ? cs.surfaceContainerHighest : cs.surfaceContainerHigh;

    const ok = Color(0xFF22C55E);
    const bad = Color(0xFFEF4444);
    const neutral = Color(0xFF64748B);

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
            child: RoundXButton(onTap: () => _goHome(context)),
          ),
          title: Text(
            loc.quiz_review,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: RoundXButton(onTap: () => _goHome(context)),
        ),
        title: Text(
          loc.quiz_review,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          for (final g in groups) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: Text(
                  _categoryTitle(loc, g.sectionIndex),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),

            // ✅ Always 2 per row
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.55,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, i) {
                    final t = g.tiles[i];

                    final isBlank = t.userAnswer == null;
                    final accent = isBlank ? neutral : (t.isCorrect ? ok : bad);
                    final icon = isBlank
                        ? Icons.help_outline_rounded
                        : (t.isCorrect ? Icons.check_circle : Icons.cancel);

                    final shadow = BoxShadow(
                      color: cs.shadow.withOpacity(isDark ? 0.35 : 0.12),
                      blurRadius: isDark ? 18 : 16,
                      offset: const Offset(0, 10),
                    );

                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MockSingleReviewPage(
                              questions: g.questions,
                              answers: g.answers,
                              initialIndex: t.localIndex,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: tileBg,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [shadow],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(isDark ? 0.22 : 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Q${t.globalNumber}', // ✅ global number only
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      color: isDark ? Colors.white : accent,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(icon, color: accent, size: 18),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: Text(
                                t.context,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    loc.quiz_tap_to_review,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: cs.onSurfaceVariant.withOpacity(0.85),
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: cs.onSurfaceVariant.withOpacity(0.85),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: g.tiles.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionGroup {
  final int sectionIndex; // 1-based order in attempt.sections
  final List<MockQuestion> questions; // ✅ MockQuestion list
  final Map<int, String> answers; // local index -> picked
  final List<_OverviewTile> tiles;

  _SectionGroup({
    required this.sectionIndex,
    required this.questions,
    required this.answers,
    required this.tiles,
  });
}

class _OverviewTile {
  final int globalNumber;
  final int localIndex;
  final String context;

  final String? userAnswer;
  final bool isCorrect;

  _OverviewTile({
    required this.globalNumber,
    required this.localIndex,
    required this.context,
    required this.userAnswer,
    required this.isCorrect,
  });
}
