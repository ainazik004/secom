import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:secom/widgets/quiz_runner.dart';

class TopicQuizPage extends StatelessWidget {
  final String topic;
  final String language;
  final String section;
  final int limit;
  final bool shuffle;

  const TopicQuizPage({
    super.key,
    required this.topic,
    this.language = 'ru',
    this.section = 'math',
    this.limit = 20,
    this.shuffle = true,
  });

  Future<List<Question>> _loadQuestions() async {
    final qs = await FirebaseFirestore.instance
        .collection('questions')
        .where('topic', isEqualTo: topic)
        .where('language', isEqualTo: language)
        .where('section', isEqualTo: section)
        .get();

    return qs.docs.map((d) => Question.fromMap(d.data())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return QuizRunner(
      title: topic,
      loader: _loadQuestions,
      statsSectionKey: section, // "math" => math.answered, math.avgScore, etc.
      limit: limit,
      shuffle: shuffle,
    );
  }
}
