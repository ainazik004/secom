import 'dart:math';

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

    final base = FirebaseFirestore.instance.collection('questions');

    final qLang = base
        .doc(lang)
        .collection(sec)
        .orderBy('importedAt', descending: true)
        .limit(limit);

    final qNeutral = base
        .doc('neutral')
        .collection(sec)
        .orderBy('importedAt', descending: true)
        .limit(limit);

    try {
      final snaps = await Future.wait([
        qLang.get(),
        qNeutral.get(),
      ]);

      final docs = <Question>[];

      for (final snap in snaps) {
        for (final d in snap.docs) {
          final data = d.data();

          data['id'] ??= d.id;
          data['section'] ??= sec;

          // ✅ your Question model uses "language" (not "lang")
          data['language'] ??= lang;

          docs.add(Question.fromMap(data));
        }
      }

      if (docs.isEmpty) {
        throw StateError('No questions available for "$sec" ($lang + neutral).');
      }

      // Shuffle and apply limit again after merging
      if (shuffle) docs.shuffle(Random());
      if (limit > 0 && docs.length > limit) {
        return docs.take(limit).toList();
      }

      return docs;
    } on FirebaseException catch (e) {
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
