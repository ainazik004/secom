import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:secom/gen_l10n/app_localizations.dart';

class QuizRunner extends StatefulWidget {
  final String title; // AppBar title
  final Future<List<Question>> Function() loader;

  /// Map field key in user doc, e.g. "math"
  final String statsSectionKey;

  final int limit; // 0 = all
  final bool shuffle;

  const QuizRunner({
    super.key,
    required this.title,
    required this.loader,
    required this.statsSectionKey,
    this.limit = 20,
    this.shuffle = true,
  });

  @override
  State<QuizRunner> createState() => _QuizRunnerState();
}

class _QuizRunnerState extends State<QuizRunner> {
  late Future<List<Question>> _future;

  int _index = 0;
  int _correctThisRun = 0;

  String? _selectedOption;
  bool _revealed = false;

  bool _trophyAwardedForThisQuestion = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Question>> _load() async {
    var list = await widget.loader();
    if (widget.shuffle) list.shuffle(Random());
    if (widget.limit > 0 && list.length > widget.limit) {
      list = list.take(widget.limit).toList();
    }
    return list;
  }

  DocumentReference<Map<String, dynamic>>? _userRef() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  Future<void> _awardTrophyPoint() async {
    final ref = _userRef();
    if (ref == null) return;

    await ref.set(
      {'trophies': FieldValue.increment(1)},
      SetOptions(merge: true),
    );
  }

  Future<void> _commitCompletionStats({
    required int totalQuestions,
    required int correct,
  }) async {
    final ref = _userRef();
    if (ref == null) return;

    final section = widget.statsSectionKey;
    final scorePct = totalQuestions == 0 ? 0.0 : (correct / totalQuestions) * 100.0;

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, dynamic>{};
      final sectionMap = (data[section] as Map<String, dynamic>?) ?? {};

      final int oldAnswered = (sectionMap['answered'] as num?)?.toInt() ?? 0;
      final int oldCorrect = (sectionMap['correct'] as num?)?.toInt() ?? 0;
      final int oldTests = (sectionMap['testsCompleted'] as num?)?.toInt() ?? 0;
      final double oldAvg = (sectionMap['avgScore'] as num?)?.toDouble() ?? 0.0;

      final int newAnswered = oldAnswered + totalQuestions;
      final int newCorrect = oldCorrect + correct;
      final int newTests = oldTests + 1;
      final double newAvg = ((oldAvg * oldTests) + scorePct) / newTests;

      tx.set(
        ref,
        {
          '$section.answered': newAnswered,
          '$section.correct': newCorrect,
          '$section.testsCompleted': newTests,
          '$section.avgScore': newAvg,
        },
        SetOptions(merge: true),
      );
    });
  }

  void _select(String key, Question q) {
    if (_revealed) return;

    setState(() {
      _selectedOption = key;
      _revealed = true;
    });

    final isCorrect = key == q.answer;
    if (isCorrect) {
      setState(() => _correctThisRun++);
      if (!_trophyAwardedForThisQuestion) {
        _trophyAwardedForThisQuestion = true;
        _awardTrophyPoint();
      }
    }
  }

  void _next(int total) {
    if (_index >= total - 1) {
      _showResult(total);
      return;
    }
    setState(() {
      _index++;
      _selectedOption = null;
      _revealed = false;
      _trophyAwardedForThisQuestion = false;
    });
  }

  void _restart() {
    setState(() {
      _index = 0;
      _correctThisRun = 0;
      _selectedOption = null;
      _revealed = false;
      _trophyAwardedForThisQuestion = false;
      _future = _load();
    });
  }

  Future<void> _showResult(int total) async {
    await _commitCompletionStats(totalQuestions: total, correct: _correctThisRun);

    final loc = AppLocalizations.of(context)!;
    final scorePct = total == 0 ? 0 : ((_correctThisRun / total) * 100).round();

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(loc.quiz_result_title),
          content: Text(
            '${loc.quiz_correct_out_of(_correctThisRun, total)}\n'
                '${loc.quiz_score_pct(scorePct)}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: Text(loc.quiz_close),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _restart();
              },
              child: Text(loc.quiz_retry),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    const purple = Color(0xFF2C015D);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        title: Text(widget.title, style: const TextStyle(fontSize: 14)),
      ),
      body: FutureBuilder<List<Question>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorState(
              title: loc.quiz_load_error_title,
              errorText: snap.error.toString(),
              retryText: loc.quiz_retry_btn,
              onRetry: () => setState(() => _future = _load()),
            );
          }

          final questions = snap.data ?? const <Question>[];
          if (questions.isEmpty) {
            return _EmptyState(
              title: loc.quiz_empty_title,
              subtitle: loc.quiz_empty_subtitle,
              backText: loc.quiz_back,
              onBack: () => Navigator.of(context).pop(),
            );
          }

          final q = questions[_index];
          final progress = (_index + 1) / questions.length;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 10,
                        offset: Offset(0, 4),
                        color: Color(0x14000000),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              loc.quiz_question_of(_index + 1, questions.length),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text('$_correctThisRun',
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(width: 6),
                          const Icon(Icons.emoji_events_outlined, size: 18),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFEAE7FF),
                          valueColor: const AlwaysStoppedAnimation<Color>(purple),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _Pill(text: loc.quiz_difficulty(q.difficulty ?? '-')),
                          const SizedBox(width: 8),
                          if ((q.language ?? '').trim().isNotEmpty)
                            _Pill(text: q.language!.toUpperCase()),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: ListView(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 10,
                              offset: Offset(0, 4),
                              color: Color(0x14000000),
                            ),
                          ],
                        ),
                        child: Text(
                          q.stem,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...q.optionKeys.map((key) {
                        final text = q.options[key] ?? '';

                        final isSelected = _selectedOption == key;
                        final isCorrect = key == q.answer;

                        Color border = const Color(0xFFE6E6E6);
                        Color fill = Colors.white;

                        if (_revealed) {
                          if (isCorrect) {
                            border = const Color(0xFF22C55E);
                            fill = const Color(0xFFE9FBEF);
                          } else if (isSelected && !isCorrect) {
                            border = const Color(0xFFEF4444);
                            fill = const Color(0xFFFDECEC);
                          }
                        } else if (isSelected) {
                          border = purple;
                          fill = const Color(0xFFF1EDFF);
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _select(key, q),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: fill,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: border, width: 1.2),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF6F4FF),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFE6E6E6)),
                                    ),
                                    child: Text(key,
                                        style: const TextStyle(fontWeight: FontWeight.w800)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      text,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.35,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      if (_revealed) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE6E6E6)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedOption == q.answer
                                    ? loc.quiz_correct
                                    : loc.quiz_wrong_correct_answer(q.answer),
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 8),
                              if ((q.explanation ?? '').trim().isNotEmpty)
                                Text(q.explanation!.trim(),
                                    style: const TextStyle(height: 1.35)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _revealed ? () => _next(questions.length) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      disabledBackgroundColor: purple.withOpacity(0.35),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _index == questions.length - 1 ? loc.quiz_finish : loc.quiz_next,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Model
class Question {
  final String id;
  final String stem;
  final Map<String, dynamic> options;
  final String answer;
  final String? explanation;
  final String? difficulty;
  final String? topic;
  final String? language;
  final String? section;

  const Question({
    required this.id,
    required this.stem,
    required this.options,
    required this.answer,
    this.explanation,
    this.difficulty,
    this.topic,
    this.language,
    this.section,
  });

  List<String> get optionKeys {
    final keys = options.keys.map((e) => e.toString()).toList();
    keys.sort();
    return keys;
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: (map['id'] ?? '').toString(),
      stem: (map['stem'] ?? '').toString(),
      options: (map['options'] as Map<String, dynamic>? ?? const {}),
      answer: (map['answer'] ?? '').toString(),
      explanation: map['explanation']?.toString(),
      difficulty: map['difficulty']?.toString(),
      topic: map['topic']?.toString(),
      language: map['language']?.toString(),
      section: map['section']?.toString(),
    );
  }
}

/// UI helpers
class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F4FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String backText;
  final VoidCallback onBack;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.backText,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 42),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: onBack, child: Text(backText)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String title;
  final String errorText;
  final String retryText;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.title,
    required this.errorText,
    required this.retryText,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(errorText, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: onRetry, child: Text(retryText)),
          ],
        ),
      ),
    );
  }
}
