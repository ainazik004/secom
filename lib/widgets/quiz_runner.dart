import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';

class QuizRunner extends StatefulWidget {
  final String title;

  /// Loader MUST return questions for canonical language code: "ru" or "ky"
  final Future<List<Question>> Function(String languageCode) loader;

  /// e.g. "math", "reading", "grammar", "analogy"
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

  String _currentLang = 'ru';
  bool _initialized = false;

  // time per question
  DateTime _questionStartedUtc = DateTime.now().toUtc();

  // Fixed timezone day boundary for Kyrgyzstan: UTC+6
  static const Duration _tzOffset = Duration(hours: 6);

  @override
  void initState() {
    super.initState();
    _future = Future.value(const <Question>[]);
    _questionStartedUtc = DateTime.now().toUtc();
  }

  String _normalizedLang(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    if (code.startsWith('ru')) return 'ru';
    if (code.startsWith('ky')) return 'ky';
    return 'ru';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final lang = _normalizedLang(context);

    final needReload = !_initialized || _currentLang != lang;
    if (!needReload) return;

    _initialized = true;
    _currentLang = lang;

    // reset run state
    _index = 0;
    _correctThisRun = 0;
    _selectedOption = null;
    _revealed = false;
    _trophyAwardedForThisQuestion = false;
    _questionStartedUtc = DateTime.now().toUtc();

    _future = _load();
    setState(() {});
  }

  Future<List<Question>> _load() async {
    var list = await widget.loader(_currentLang);

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

  // ─────────────────────────────────────────
  // UTC+6 Day Keys (YYYY-MM-DD)
  // ─────────────────────────────────────────
  String _dayKeyUtcPlus6(DateTime utcNow) {
    final local = utcNow.toUtc().add(_tzOffset);
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _yesterdayKeyUtcPlus6(DateTime utcNow) {
    final local = utcNow.toUtc().add(_tzOffset);
    final yest = DateTime(local.year, local.month, local.day)
        .subtract(const Duration(days: 1));
    final y = yest.year.toString().padLeft(4, '0');
    final m = yest.month.toString().padLeft(2, '0');
    final d = yest.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  double _asDouble(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  String? _asDayKeyFromLastTestDate(dynamic v) {
    if (v == null) return null;
    if (v is String && v.trim().isNotEmpty) return v.trim();
    if (v is Timestamp) {
      return _dayKeyUtcPlus6(v.toDate().toUtc());
    }
    return null;
  }

  Future<void> _awardTrophyPoint() async {
    final ref = _userRef();
    if (ref == null) return;

    await ref.set(
      {'trophies': FieldValue.increment(1)},
      SetOptions(merge: true),
    );
  }

  /// ✅ Per-question update:
  /// - ONLY updates categoryStats.<section> (answered/correct/avgScore)
  /// - Also updates global totals/time fields
  Future<void> _commitPerQuestionStats({
    required bool isCorrect,
    required int timeSpentSeconds,
  }) async {
    final ref = _userRef();
    if (ref == null) return;

    final section = widget.statsSectionKey;

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, dynamic>{};

      final catStats = (data['categoryStats'] as Map<String, dynamic>?) ?? {};
      final catSection = (catStats[section] as Map<String, dynamic>?) ?? {};

      final int oldAnswered = _asInt(catSection['answered'], fallback: 0);
      final int oldCorrect = _asInt(catSection['correct'], fallback: 0);

      final int newAnswered = oldAnswered + 1;
      final int newCorrect = oldCorrect + (isCorrect ? 1 : 0);
      final double newAvgScore =
      newAnswered == 0 ? 0.0 : (newCorrect / newAnswered) * 100.0;

      // global totals
      final int oldTotalAnswered =
      _asInt(data['totalQuestionsAnswered'], fallback: 0);
      final int oldTotalCorrect =
      _asInt(data['totalCorrectAnswers'], fallback: 0);
      final int oldTotalStudySeconds =
      _asInt(data['totalStudyTimeSeconds'], fallback: 0);

      final int newTotalAnswered = oldTotalAnswered + 1;
      final int newTotalCorrect = oldTotalCorrect + (isCorrect ? 1 : 0);
      final int newTotalStudySeconds = oldTotalStudySeconds + timeSpentSeconds;

      final double newAvgTimePerQuestion =
      newTotalAnswered == 0 ? 0.0 : (newTotalStudySeconds / newTotalAnswered);

      tx.set(
        ref,
        {
          // ✅ only categoryStats.<section> for per-category performance
          'categoryStats': {
            ...catStats,
            section: {
              ...catSection,
              'answered': newAnswered,
              'correct': newCorrect,
              'avgScore': newAvgScore,
            },
          },

          // ✅ global totals
          'totalQuestionsAnswered': newTotalAnswered,
          'totalCorrectAnswers': newTotalCorrect,
          'totalStudyTimeSeconds': newTotalStudySeconds,
          'averageTimePerQuestionSeconds': newAvgTimePerQuestion,
        },
        SetOptions(merge: true),
      );
    });
  }

  /// End-of-quiz:
  /// - increments categoryStats.<section>.testsCompleted
  /// - updates streak fields + longestStreakDays
  /// - updates global derived fields: totalTestsCompleted, averageScore
  /// - ✅ stores last 7 test accuracies under `recentResults` as subfields:
  ///   recentResults: { r0: <oldest>, r1: ..., r6: <newest> }
  ///   When adding 8th, drops oldest.
  Future<void> _commitCompletionAndStreak({
    required int totalQuestions,
    required int correct,
  }) async {
    final ref = _userRef();
    if (ref == null) return;

    final section = widget.statsSectionKey;

    final nowUtc = DateTime.now().toUtc();
    final todayKey = _dayKeyUtcPlus6(nowUtc);
    final yesterdayKey = _yesterdayKeyUtcPlus6(nowUtc);

    // accuracy percent 0..100
    final double thisTestAccuracyPct = totalQuestions == 0
        ? 0.0
        : ((correct / totalQuestions) * 100.0).clamp(0.0, 100.0);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, dynamic>{};

      // ───── categoryStats ─────
      final Map<String, dynamic> catStats =
          (data['categoryStats'] as Map<String, dynamic>?) ?? {};

      final Map<String, dynamic> catSection =
          (catStats[section] as Map<String, dynamic>?) ?? {};

      final int oldTests = _asInt(catSection['testsCompleted'], fallback: 0);

      // ───── streak logic ─────
      final int currentStreak = _asInt(data['currentStreakDays'], fallback: 0);
      final int longestStreak = _asInt(data['longestStreakDays'], fallback: 0);
      final String? lastKey = _asDayKeyFromLastTestDate(data['lastTestDate']);

      int updatedStreak;
      if (lastKey == todayKey) {
        updatedStreak = currentStreak;
      } else if (lastKey == yesterdayKey) {
        updatedStreak = currentStreak <= 0 ? 1 : currentStreak + 1;
      } else {
        updatedStreak = 1;
      }

      final int updatedLongest =
      updatedStreak > longestStreak ? updatedStreak : longestStreak;

      // ───── recompute GLOBAL averageScore from categoryStats ─────
      double sum = 0.0;
      int count = 0;

      for (final entry in catStats.entries) {
        final v = entry.value;
        if (v is Map<String, dynamic>) {
          final answered = _asInt(v['answered']);
          final avg = _asDouble(v['avgScore']);
          if (answered > 0) {
            sum += avg;
            count++;
          }
        }
      }

      final double newGlobalAvgScore = count == 0 ? 0.0 : (sum / count);

      // ───── global tests completed ─────
      final int oldTotalTests = _asInt(data['totalTestsCompleted'], fallback: 0);

      // ───── recentResults (map of subfields r0..r6) ─────
      final Map<String, dynamic> oldRecent =
      (data['recentResults'] is Map<String, dynamic>)
          ? Map<String, dynamic>.from(data['recentResults'] as Map)
          : <String, dynamic>{};

      // Extract values in order r0..rN (oldest->newest)
      final List<double> recentList = [];
      for (int i = 0; i < 50; i++) {
        final k = 'r$i';
        if (!oldRecent.containsKey(k)) break;
        recentList.add(_asDouble(oldRecent[k]).clamp(0.0, 100.0));
      }

      // append newest
      recentList.add(thisTestAccuracyPct);

      // keep only last 7 (drop oldest)
      while (recentList.length > 7) {
        recentList.removeAt(0);
      }

      // rebuild as subfields r0..r6
      final Map<String, dynamic> newRecent = <String, dynamic>{};
      for (int i = 0; i < recentList.length; i++) {
        newRecent['r$i'] = recentList[i];
      }

      // ───── write ─────
      tx.set(
        ref,
        {
          // category-level increment
          'categoryStats': {
            ...catStats,
            section: {
              ...catSection,
              'testsCompleted': oldTests + 1,
            },
          },

          // global derived fields
          'totalTestsCompleted': oldTotalTests + 1,
          'averageScore': newGlobalAvgScore,

          // ✅ recent results as subfields
          'recentResults': newRecent,

          // streak
          'currentStreakDays': updatedStreak,
          'longestStreakDays': updatedLongest,
          'lastTestDate': todayKey,
        },
        SetOptions(merge: true),
      );
    });
  }

  void _select(String key, Question q) {
    if (_revealed) return;

    final nowUtc = DateTime.now().toUtc();
    final int timeSpentSeconds =
    nowUtc.difference(_questionStartedUtc).inSeconds.clamp(0, 60 * 60);

    setState(() {
      _selectedOption = key;
      _revealed = true;
    });

    final isCorrect = key == q.answer;

    // ✅ immediate per-question stats (categoryStats only) + global totals/time
    _commitPerQuestionStats(
      isCorrect: isCorrect,
      timeSpentSeconds: timeSpentSeconds,
    );

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
      _questionStartedUtc = DateTime.now().toUtc();
    });
  }

  void _restart() {
    setState(() {
      _index = 0;
      _correctThisRun = 0;
      _selectedOption = null;
      _revealed = false;
      _trophyAwardedForThisQuestion = false;
      _questionStartedUtc = DateTime.now().toUtc();
      _future = _load();
    });
  }

  Future<void> _showResult(int total) async {
    await _commitCompletionAndStreak(
      totalQuestions: total,
      correct: _correctThisRun,
    );

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
                          Text(
                            '$_correctThisRun',
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
                          valueColor: const AlwaysStoppedAnimation<Color>(purple),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _Pill(text: loc.quiz_difficulty(q.difficulty ?? '-')),
                          const SizedBox(width: 8),
                          _Pill(text: _currentLang.toUpperCase()),
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
                                      border: Border.all(
                                        color: const Color(0xFFE6E6E6),
                                      ),
                                    ),
                                    child: Text(
                                      key,
                                      style: const TextStyle(fontWeight: FontWeight.w800),
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
                                    ? loc.quiz_correct
                                    : loc.quiz_wrong_correct_answer(q.answer),
                                style: const TextStyle(fontWeight: FontWeight.w800),
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
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
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
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
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
