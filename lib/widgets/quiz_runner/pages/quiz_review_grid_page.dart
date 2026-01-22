import 'package:flutter/material.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';
import '../models/question.dart';
import '../widgets/round_x_button.dart';
import 'quiz_single_review_page.dart';

class QuizReviewGridPage extends StatelessWidget {
  final List<Question> questions;
  final Map<int, String> answers;

  const QuizReviewGridPage({
    super.key,
    required this.questions,
    required this.answers,
  });

  bool _isCorrect(int i) {
    final picked = answers[i];
    if (picked == null) return false;
    return picked == questions[i].answer;
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ Background darker, tiles lighter (both themes)
    final pageBg = cs.surface; // good base for both
    final tileBg = isDark ? cs.surfaceContainerHighest : cs.surfaceContainerHigh;

    // Status colors (consistent, but still readable on both themes)
    const ok = Color(0xFF22C55E); // green
    const bad = Color(0xFFEF4444); // red

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
          final crossAxisCount = w >= 900
              ? 5
              : w >= 600
              ? 4
              : 2;

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

              // ✅ No borderlines + visible shadow in both themes
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
                      builder: (_) => QuizSingleReviewPage(
                        questions: questions,
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
                          // ✅ status pill (no border)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
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
                          Icon(
                            icon,
                            color: accent,
                            size: 18,
                          ),
                        ],
                      ),
                      const Spacer(),
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
