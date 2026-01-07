import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TopicQuizPage extends StatefulWidget {
  final String topic; // e.g. "geometry/polygon_diagonals"
  final String language; // e.g. "ru"
  final String section; // e.g. "math"
  final int limit; // how many questions to take
  final bool shuffle;

  const TopicQuizPage({
    super.key,
    required this.topic,
    this.language = 'ru',
    this.section = 'math',
    this.limit = 20,
    this.shuffle = true,
  });

  @override
  State<TopicQuizPage> createState() => _TopicQuizPageState();
}

class _TopicQuizPageState extends State<TopicQuizPage> {
  late Future<List<Question>> _future;

  int _index = 0;
  int _correct = 0;

  String? _selectedOption; // "A".."E"
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _future = _loadQuestions();
  }

  Future<List<Question>> _loadQuestions() async {
    final qs = await FirebaseFirestore.instance
        .collection('questions')
        .where('topic', isEqualTo: widget.topic)
        .where('language', isEqualTo: widget.language)
        .where('section', isEqualTo: widget.section)
        .get();

    var list = qs.docs.map((d) => Question.fromMap(d.data())).toList();

    if (widget.shuffle) {
      list.shuffle(Random());
    }

    if (widget.limit > 0 && list.length > widget.limit) {
      list = list.take(widget.limit).toList();
    }

    return list;
  }

  void _select(String key, Question q) {
    if (_revealed) return;

    setState(() {
      _selectedOption = key;
      _revealed = true;
      if (key == q.answer) _correct++;
    });
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
    });
  }

  void _restart() {
    setState(() {
      _index = 0;
      _correct = 0;
      _selectedOption = null;
      _revealed = false;
      _future = _loadQuestions();
    });
  }

  Future<void> _showResult(int total) async {
    final scorePct = total == 0 ? 0 : ((_correct / total) * 100).round();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Результат'),
          content: Text('Правильных: $_correct из $total\nБаллы: $scorePct%'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(); // back to topics
              },
              child: const Text('Закрыть'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _restart();
              },
              child: const Text('Пройти снова'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF2C015D);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        title: Text(
          widget.topic,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: FutureBuilder<List<Question>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorState(
              errorText: snap.error.toString(),
              onRetry: () => setState(() => _future = _loadQuestions()),
            );
          }

          final questions = snap.data ?? const <Question>[];
          if (questions.isEmpty) {
            return _EmptyState(
              onBack: () => Navigator.of(context).pop(),
              subtitle:
              'Нет вопросов для этого topic.\nПроверьте Firestore: /questions topic="${widget.topic}".',
            );
          }

          final q = questions[_index];
          final progress = (_index + 1) / questions.length;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header (progress + score)
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
                              'Вопрос ${_index + 1} из ${questions.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '$_correct',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
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
                          valueColor:
                          const AlwaysStoppedAnimation<Color>(purple),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _Pill(text: 'Difficulty: ${q.difficulty ?? "-"}'),
                          const SizedBox(width: 8),
                          _Pill(text: widget.language.toUpperCase()),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Question card
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
                                      border: Border.all(
                                        color: const Color(0xFFE6E6E6),
                                      ),
                                    ),
                                    child: Text(
                                      key,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
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
                                    ? 'Верно ✅'
                                    : 'Неверно ❌ (правильный ответ: ${q.answer})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if ((q.explanation ?? '').trim().isNotEmpty)
                                Text(
                                  q.explanation!.trim(),
                                  style: const TextStyle(height: 1.35),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Bottom button
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
                      _index == questions.length - 1 ? 'Завершить' : 'Далее',
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
    keys.sort(); // A,B,C...
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
  final VoidCallback onBack;
  final String subtitle;

  const _EmptyState({required this.onBack, required this.subtitle});

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
            const Text(
              'Пусто',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: onBack, child: const Text('Назад')),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String errorText;
  final VoidCallback onRetry;

  const _ErrorState({required this.errorText, required this.onRetry});

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
            const Text(
              'Ошибка загрузки',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(errorText, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
