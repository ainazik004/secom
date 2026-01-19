// lib/widgets/quiz_runner/quiz_runner/quiz_runner.dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:zhalbyrak/gen_l10n/app_localizations.dart';

// ✅ split files (based on your folder structure screenshot)
import '../models/question.dart';
import '../pages/quiz_review_grid_page.dart';

import '../services/ai_explain_service.dart';
import '../theme/z_theme.dart';

import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/result_popup.dart';
import '../widgets/round_x_button.dart';

class QuizRunner extends StatefulWidget {
  final String title;
  final Future<List<Question>> Function(String languageCode) loader;
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
  final Map<int, String> _answers = {};
  final Map<int, int> _timeSpentSecondsByIndex = {};
  DateTime _questionStartedUtc = DateTime.now().toUtc();

  String _currentLang = 'ru';
  bool _initialized = false;

  bool _finishing = false;
  bool _resultDialogShown = false;

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

    _resetRunState();
    _future = _load();
    setState(() {});
  }

  void _resetRunState() {
    _index = 0;
    _answers.clear();
    _timeSpentSecondsByIndex.clear();
    _questionStartedUtc = DateTime.now().toUtc();
    _finishing = false;
    _resultDialogShown = false;
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

  String _dayKeyUtcPlus6(DateTime utcNow) {
    final local = utcNow.toUtc().add(_tzOffset);
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _yesterdayKeyUtcPlus6(DateTime utcNow) {
    final local = utcNow.toUtc().add(_tzOffset);
    final yest =
    DateTime(local.year, local.month, local.day).subtract(const Duration(days: 1));
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
    if (v is Timestamp) return _dayKeyUtcPlus6(v.toDate().toUtc());
    return null;
  }

  void _finalizeTimeForCurrentQuestion() {
    final nowUtc = DateTime.now().toUtc();
    final spent = nowUtc.difference(_questionStartedUtc).inSeconds;
    final clamped = spent.clamp(0, 60 * 60);
    _timeSpentSecondsByIndex[_index] = (_timeSpentSecondsByIndex[_index] ?? 0) + clamped;
    _questionStartedUtc = nowUtc;
  }

  int _totalStudySeconds() {
    var sum = 0;
    for (final v in _timeSpentSecondsByIndex.values) {
      sum += v;
    }
    return sum;
  }

  int _computeCorrect(List<Question> questions) {
    var correct = 0;
    for (var i = 0; i < questions.length; i++) {
      final picked = _answers[i];
      if (picked != null && picked == questions[i].answer) correct++;
    }
    return correct;
  }

  Future<void> _commitQuizOnce({required List<Question> questions}) async {
    final ref = _userRef();
    if (ref == null) return;

    final section = widget.statsSectionKey;
    final totalQuestions = questions.length;

    var correct = 0;
    for (var i = 0; i < questions.length; i++) {
      final picked = _answers[i];
      if (picked != null && picked == questions[i].answer) correct++;
    }

    final nowUtc = DateTime.now().toUtc();
    final todayKey = _dayKeyUtcPlus6(nowUtc);
    final yesterdayKey = _yesterdayKeyUtcPlus6(nowUtc);
    final totalStudySeconds = _totalStudySeconds();

    final double thisTestAccuracyPct = totalQuestions == 0
        ? 0.0
        : ((correct / totalQuestions) * 100.0).clamp(0.0, 100.0);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, dynamic>{};

      final Map<String, dynamic> catStats =
          (data['categoryStats'] as Map<String, dynamic>?) ?? {};
      final Map<String, dynamic> catSection =
          (catStats[section] as Map<String, dynamic>?) ?? {};

      final oldAnswered = _asInt(catSection['answered'], fallback: 0);
      final oldCorrect = _asInt(catSection['correct'], fallback: 0);
      final oldTests = _asInt(catSection['testsCompleted'], fallback: 0);

      final newAnswered = oldAnswered + totalQuestions;
      final newCorrect = oldCorrect + correct;
      final newAvgScore = newAnswered == 0 ? 0.0 : (newCorrect / newAnswered) * 100.0;

      final updatedCatStats = <String, dynamic>{
        ...catStats,
        section: {
          ...catSection,
          'answered': newAnswered,
          'correct': newCorrect,
          'avgScore': newAvgScore,
          'testsCompleted': oldTests + 1,
        },
      };

      final oldTotalAnswered = _asInt(data['totalQuestionsAnswered'], fallback: 0);
      final oldTotalCorrect = _asInt(data['totalCorrectAnswers'], fallback: 0);
      final oldTotalStudySeconds = _asInt(data['totalStudyTimeSeconds'], fallback: 0);

      final newTotalAnswered = oldTotalAnswered + totalQuestions;
      final newTotalCorrect = oldTotalCorrect + correct;
      final newTotalStudySeconds = oldTotalStudySeconds + totalStudySeconds;

      final newAvgTimePerQuestion =
      newTotalAnswered == 0 ? 0.0 : (newTotalStudySeconds / newTotalAnswered);

      final currentStreak = _asInt(data['currentStreakDays'], fallback: 0);
      final longestStreak = _asInt(data['longestStreakDays'], fallback: 0);
      final lastKey = _asDayKeyFromLastTestDate(data['lastTestDate']);

      int updatedStreak;
      if (lastKey == todayKey) {
        updatedStreak = currentStreak;
      } else if (lastKey == yesterdayKey) {
        updatedStreak = currentStreak <= 0 ? 1 : currentStreak + 1;
      } else {
        updatedStreak = 1;
      }
      final updatedLongest = updatedStreak > longestStreak ? updatedStreak : longestStreak;

      final Map<String, dynamic> oldRecent =
      (data['recentResults'] is Map<String, dynamic>)
          ? Map<String, dynamic>.from(data['recentResults'] as Map)
          : <String, dynamic>{};

      final recentList = <double>[];
      for (int i = 0; i < 50; i++) {
        final k = 'r$i';
        if (!oldRecent.containsKey(k)) break;
        recentList.add(_asDouble(oldRecent[k]).clamp(0.0, 100.0));
      }
      recentList.add(thisTestAccuracyPct);
      while (recentList.length > 7) {
        recentList.removeAt(0);
      }
      final newRecent = <String, dynamic>{};
      for (int i = 0; i < recentList.length; i++) {
        newRecent['r$i'] = recentList[i];
      }

      final oldTotalTests = _asInt(data['totalTestsCompleted'], fallback: 0);

      double sum = 0.0;
      int count = 0;
      for (final entry in updatedCatStats.entries) {
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
      final newGlobalAvgScore = count == 0 ? 0.0 : (sum / count);

      final trophiesInc = correct;

      tx.set(
        ref,
        {
          'categoryStats': updatedCatStats,
          'totalQuestionsAnswered': newTotalAnswered,
          'totalCorrectAnswers': newTotalCorrect,
          'totalStudyTimeSeconds': newTotalStudySeconds,
          'averageTimePerQuestionSeconds': newAvgTimePerQuestion,
          'totalTestsCompleted': oldTotalTests + 1,
          'averageScore': newGlobalAvgScore,
          'recentResults': newRecent,
          'currentStreakDays': updatedStreak,
          'longestStreakDays': updatedLongest,
          'lastTestDate': todayKey,
          if (trophiesInc > 0) 'trophies': FieldValue.increment(trophiesInc),
        },
        SetOptions(merge: true),
      );
    });
  }

  void _select(String key) {
    if (_finishing) return;
    setState(() => _answers[_index] = key);
  }

  void _goBackQuestion() {
    if (_index <= 0 || _finishing) return;
    _finalizeTimeForCurrentQuestion();
    setState(() => _index--);
  }

  void _goNextQuestion(int total) {
    if (_finishing) return;
    if ((_answers[_index] ?? '').isEmpty) return;
    if (_index >= total - 1) return;

    _finalizeTimeForCurrentQuestion();
    setState(() => _index++);
  }

  void _restart() {
    setState(() {
      _resetRunState();
      _future = _load();
    });
  }

  Future<void> _finish(List<Question> questions) async {
    if (_finishing || _resultDialogShown) return;
    if ((_answers[_index] ?? '').isEmpty) return;

    setState(() => _finishing = true);

    _finalizeTimeForCurrentQuestion();
    await _commitQuizOnce(questions: questions);

    if (!mounted) return;
    _resultDialogShown = true;

    final correct = _computeCorrect(questions);

    await _showResultDialog(
      questions: questions,
      correct: correct,
      total: questions.length,
    );

    if (mounted) setState(() => _finishing = false);
  }

  Future<void> _showResultDialog({
    required List<Question> questions,
    required int correct,
    required int total,
  }) async {
    final loc = AppLocalizations.of(context)!;
    final pct = total == 0 ? 0 : ((correct / total) * 100).round();

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'result',
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final t = Curves.easeOutCubic.transform(anim.value);

        return Opacity(
          opacity: anim.value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - t)),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
              child: ResultPopup(
                title: loc.quiz_result_title,
                brand: 'ZHALBYRAK',
                percent: pct,
                correctText: loc.quiz_correct_out_of(correct, total),
                correctCountLabel: loc.quiz_correct,
                correctCount: '$correct',
                totalLabel: loc.quiz_total,
                totalCount: '$total',
                reviewText: loc.quiz_review,
                closeText: loc.quiz_close,
                retryText: loc.quiz_retry,
                onReview: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuizReviewGridPage(
                        questions: questions,
                        answers: Map<int, String>.from(_answers),
                      ),
                    ),
                  );
                },
                onClose: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop(); // back to home
                },
                onRetry: () {
                  Navigator.of(ctx).pop();
                  _restart();
                },
              ),
            ),
          ),
        );
      },
    );
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
          child: RoundXButton(onTap: () => Navigator.of(context).pop()),
        ),
        title: Text(widget.title, style: const TextStyle(fontSize: 14)),
      ),
      body: FutureBuilder<List<Question>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ErrorStateView(
              title: loc.quiz_load_error_title,
              errorText: snap.error.toString(),
              retryText: loc.quiz_retry_btn,
              onRetry: () => setState(() => _future = _load()),
            );
          }

          final questions = snap.data ?? const <Question>[];
          if (questions.isEmpty) {
            return EmptyStateView(
              title: loc.quiz_empty_title,
              subtitle: loc.quiz_empty_subtitle,
              backText: loc.quiz_back,
              onBack: () => Navigator.of(context).pop(),
            );
          }

          final q = questions[_index];
          final progress = (_index + 1) / questions.length;
          final selected = _answers[_index];

          final canGoBack = _index > 0 && !_finishing;
          final canGoNext = !_finishing && (selected ?? '').isNotEmpty;
          final isLast = _index == questions.length - 1;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Top progress card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: ZTheme.softShadow,
                    border: Border.all(color: ZTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              loc.quiz_question_of(_index + 1, questions.length),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: ZTheme.pillBg,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: ZTheme.border),
                            ),
                            child: Text(
                              '${_answers.length}/${questions.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 9,
                          backgroundColor: const Color(0xFFEAE7FF),
                          valueColor: AlwaysStoppedAnimation<Color>(ZTheme.purple),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Question card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: ZTheme.softShadow,
                            border: Border.all(color: ZTheme.border),
                          ),
                          child: Text(
                            q.stem,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              height: 1.35,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Answer choices
                        ...q.optionKeys.map((key) {
                          final text = q.options[key] ?? '';
                          final isSelected = selected == key;

                          final border = isSelected ? ZTheme.purple : ZTheme.border;
                          final fill = isSelected ? ZTheme.selectedFill : Colors.white;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _finishing ? null : () => _select(key),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: fill,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: border, width: 1.2),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: ZTheme.pillBg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: ZTheme.border),
                                      ),
                                      child: Text(
                                        key,
                                        style: const TextStyle(fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        text,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.35,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 6),

                        // Bottom buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: canGoBack ? _goBackQuestion : null,
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  side: BorderSide(
                                    color: canGoBack
                                        ? ZTheme.purple
                                        : ZTheme.purple.withOpacity(0.25),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: Text(
                                  loc.quiz_back,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: canGoBack
                                        ? ZTheme.purple
                                        : ZTheme.purple.withOpacity(0.35),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: canGoNext
                                    ? () {
                                  if (isLast) {
                                    _finish(questions);
                                  } else {
                                    _goNextQuestion(questions.length);
                                  }
                                }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ZTheme.purple,
                                  disabledBackgroundColor: ZTheme.purple.withOpacity(0.35),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _finishing && isLast
                                    ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                                    : Text(
                                  isLast ? loc.quiz_finish : loc.quiz_next,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        const SafeArea(top: false, child: SizedBox(height: 0)),
                      ],
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
