import 'package:flutter/material.dart';
import '../mock_models.dart';
import '../mock_question_loader.dart';
import '../mock_test_controller.dart';

class MockTestReviewPage extends StatefulWidget {
  final MockTestController controller;
  final QuestionRef ref;
  const MockTestReviewPage({super.key, required this.controller, required this.ref});

  @override
  State<MockTestReviewPage> createState() => _MockTestReviewPageState();
}

class _MockTestReviewPageState extends State<MockTestReviewPage> {
  late final MockQuestionLoader loader;

  bool loading = true;
  String? aiText;
  late String? userAnswer;

  @override
  void initState() {
    super.initState();
    loader = MockQuestionLoader(widget.controller.db);

    () async {
      await widget.controller.restore();
      userAnswer = widget.controller.attempt?.answers[widget.ref.key()];
      setState(() => loading = false);
    }();
  }

  Future<void> _loadAi(MockQuestion q) async {
    // Hook into your existing AI explain service here.
    // Example (replace with your real call):
    // aiText = await AiExplainService(...).explain(q.raw, userAnswer);
    aiText = '(AI explanation placeholder)';
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return FutureBuilder<MockQuestion>(
      future: loader.loadOne(widget.ref),
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final q = snap.data!;
        final correct = q.correct;
        final isCorrect = userAnswer != null && userAnswer == correct;

        return Scaffold(
          appBar: AppBar(title: Text('Review: ${widget.ref.id}')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text(q.stem, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Text('Your answer: ${userAnswer ?? "-"}'),
                Text('Correct answer: $correct'),
                const SizedBox(height: 8),
                Text(isCorrect ? 'Correct' : 'Wrong', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),

                if (q.isComparison) ...[
                  Row(
                    children: [
                      Expanded(child: _box('Left', q.left)),
                      const SizedBox(width: 12),
                      Expanded(child: _box('Right', q.right)),
                    ],
                  ),
                ] else ...[
                  for (final e in (q.options.entries.toList()..sort((a,b)=>a.key.compareTo(b.key))))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('${e.key}) ${e.value}'),
                    ),
                ],

                const SizedBox(height: 16),
                if (q.explanation != null && q.explanation!.isNotEmpty) ...[
                  const Text('Explanation:', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(q.explanation!),
                  const SizedBox(height: 16),
                ],

                ElevatedButton(
                  onPressed: aiText == null ? () => _loadAi(q) : null,
                  child: const Text('Ask AI to explain'),
                ),
                if (aiText != null) ...[
                  const SizedBox(height: 12),
                  const Text('AI explanation:', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(aiText!),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _box(String title, String v) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(v),
        ],
      ),
    );
  }
}
