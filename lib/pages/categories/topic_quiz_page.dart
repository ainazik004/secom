import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../widgets/quiz_runner/models/question.dart';
import '../../widgets/quiz_runner/quiz_runner/quiz_runner.dart';

class TopicQuizPage extends StatelessWidget {
  final String title;
  final String section;
  final int limit;
  final bool shuffle;

  static const Set<String> _allowedSections = {
    'math',
    'analogy',
    'reading',
    'grammar',
  };

  TopicQuizPage({
    super.key,
    required this.title,
    required this.section,
    this.limit = 20,
    this.shuffle = true,
  })  : assert(
  _allowedSections.contains(section),
  'Invalid section: $section',
  ),
        assert(limit > 0);

  Future<List<Question>> _loadQuestions(String languageCode) async {
    final lang = languageCode.toLowerCase().startsWith('ky') ? 'ky' : 'ru';
    final sec = section.toLowerCase();

    // NOTE: For this to work, each question document should have a `createdAt`
    // field (Firestore Timestamp). If you do not have it yet, add it on upload.
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('questions')
        .doc(lang)
        .collection(sec)
        .orderBy('importedAt', descending: true)
        .limit(limit);

    try {
      final snap = await q.get();

      if (snap.docs.isEmpty) {
        // Let QuizRunner display your error/empty state.
        throw StateError('No questions available for "$sec" ($lang).');
      }

      final list = snap.docs.map((d) {
        final data = d.data();

        // Ensure consistent id in your model.
        data['id'] ??= d.id;

        // Optional: ensure section/lang are present if your Question model uses them.
        data['section'] ??= sec;
        data['lang'] ??= lang;

        return Question.fromMap(data);
      }).toList();

      return list;
    } on FirebaseException catch (e) {
      // Provide a clean error message for UI.
      throw StateError('Failed to load questions ($lang/$sec): ${e.message}');
    } catch (e) {
      throw StateError('Failed to load questions ($lang/$sec): $e');
    }
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
