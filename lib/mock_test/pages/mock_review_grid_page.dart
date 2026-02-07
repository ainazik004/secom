// lib/mock_test/pages/mock_review_grid_page.dart
import 'package:flutter/material.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';

import '../../widgets/quiz_runner/widgets/round_x_button.dart';
import '../mock_question_loader.dart'; // ✅ MockQuestion
import '../mock_test_controller.dart';
import 'mock_single_review_page.dart';

class MockReviewGridPage extends StatelessWidget {
  final MockTestController controller;

  // ✅ Must match MockSingleReviewPage signature
  final List<MockQuestion> questions;

  // index-based for THIS questions list
  final Map<int, String> answers;

  const MockReviewGridPage({
    super.key,
    required this.controller,
    required this.questions,
    required this.answers,
  });

  bool _isCorrect(int i) {
    final picked = answers[i];
    if (picked == null || picked.isEmpty) return false;
    return picked == questions[i].correct;
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  bool _isComparison(MockQuestion q) {
    final t = q.topic.toLowerCase();
    return t == 'comparison' || t.startsWith('comparison/') || t.contains('/comparison') || q.isComparison;
  }

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
      body: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final crossAxisCount = w >= 900 ? 5 : w >= 600 ? 4 : 2;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: questions.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.55,
            ),
            itemBuilder: (context, i) {
              final correct = _isCorrect(i);
              final accent = correct ? ok : bad;
              final icon = correct ? Icons.check_circle : Icons.cancel;

              final shadow = BoxShadow(
                color: cs.shadow.withOpacity(isDark ? 0.35 : 0.12),
                blurRadius: isDark ? 18 : 16,
                offset: const Offset(0, 10),
              );

              final q = questions[i];
              final preview = _previewTextForTile(q);

              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MockSingleReviewPage(
                        questions: questions, // ✅ now matches List<MockQuestion>
                        answers: answers,
                        initialIndex: i,
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
                              'Q${i + 1}',
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
                          preview,
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
          );
        },
      ),
    );
  }
}
