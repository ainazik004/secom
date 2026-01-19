import 'package:flutter/material.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';
import '../models/question.dart';
import '../theme/z_theme.dart';
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

    return Scaffold(
      backgroundColor: ZTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: RoundXButton(onTap: () => _goHome(context)),
        ),
        title: Text(loc.quiz_review, style: const TextStyle(fontSize: 14)),
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
              final border = correct ? ZTheme.green : ZTheme.red;
              final pillBg = correct ? ZTheme.greenBg : ZTheme.redBg;
              final icon = correct ? Icons.check_circle : Icons.cancel;

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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: border, width: 1.3),
                    boxShadow: ZTheme.softShadow,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: pillBg,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: border.withOpacity(0.25)),
                            ),
                            child: Text(
                              'Q${i + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                color: border,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(icon, color: border, size: 18),
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
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              size: 18, color: Color(0xFF6B7280)),
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
