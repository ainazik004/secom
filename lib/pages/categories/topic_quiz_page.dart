import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zhalbyrak/widgets/quiz_runner.dart';

class TopicQuizPage extends StatelessWidget {
  // Keep topic only for UI title (optional).
  final String title;

  final String section;
  final int limit;
  final bool shuffle;

  const TopicQuizPage({
    super.key,
    required this.title,
    this.section = 'math',
    this.limit = 20,
    this.shuffle = true,
  });

  // Loader signature required by QuizRunner:
  // Future<List<Question>> Function(String languageCode)
  Future<List<Question>> _loadQuestions(String languageCode) async {
    final lang = languageCode.toLowerCase();

    final qs = await FirebaseFirestore.instance
        .collection('questions')
        .where('section', isEqualTo: section)
        .where('language', isEqualTo: lang)
        .get();

    return qs.docs.map((d) => Question.fromMap(d.data())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return QuizRunner(
      title: title,
      loader: _loadQuestions,
      statsSectionKey: section,
      limit: limit,
      shuffle: shuffle,
    );
  }
}
