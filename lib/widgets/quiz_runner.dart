import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';

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
    if (v is Timestamp) return _dayKeyUtcPlus6(v.toDate().toUtc());
    return null;
  }

  void _finalizeTimeForCurrentQuestion() {
    final nowUtc = DateTime.now().toUtc();
    final spent = nowUtc.difference(_questionStartedUtc).inSeconds;
    final clamped = spent.clamp(0, 60 * 60);
    _timeSpentSecondsByIndex[_index] =
        (_timeSpentSecondsByIndex[_index] ?? 0) + clamped;
    _questionStartedUtc = nowUtc;
  }

  int _totalStudySeconds() {
    var sum = 0;
    for (final v in _timeSpentSecondsByIndex.values) {
      sum += v;
    }
    return sum;
  }

  Future<void> _commitQuizOnce({
    required List<Question> questions,
  }) async {
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
      final newAvgScore =
      newAnswered == 0 ? 0.0 : (newCorrect / newAnswered) * 100.0;

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

      final oldTotalAnswered =
      _asInt(data['totalQuestionsAnswered'], fallback: 0);
      final oldTotalCorrect = _asInt(data['totalCorrectAnswers'], fallback: 0);
      final oldTotalStudySeconds =
      _asInt(data['totalStudyTimeSeconds'], fallback: 0);

      final newTotalAnswered = oldTotalAnswered + totalQuestions;
      final newTotalCorrect = oldTotalCorrect + correct;
      final newTotalStudySeconds = oldTotalStudySeconds + totalStudySeconds;

      final newAvgTimePerQuestion = newTotalAnswered == 0
          ? 0.0
          : (newTotalStudySeconds / newTotalAnswered);

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
      final updatedLongest =
      updatedStreak > longestStreak ? updatedStreak : longestStreak;

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

  int _computeCorrect(List<Question> questions) {
    var correct = 0;
    for (var i = 0; i < questions.length; i++) {
      final picked = _answers[i];
      if (picked != null && picked == questions[i].answer) correct++;
    }
    return correct;
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
              insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
              child: _ResultPopup(
                title: loc.quiz_result_title,
                brand: 'ZHALBYRAK',
                percent: pct,
                correctText: loc.quiz_correct_out_of(correct, total),
                correctCountLabel: loc.quiz_correct, // existing key
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
                  Navigator.of(context).pop(); // ✅ back to home
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
        // ✅ rounded X like you requested
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: _RoundXButton(
            onTap: () => Navigator.of(context).pop(), // ✅ back to home
          ),
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
          final selected = _answers[_index];

          final canGoBack = _index > 0 && !_finishing;
          final canGoNext = !_finishing && (selected ?? '').isNotEmpty;
          final isLast = _index == questions.length - 1;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: ZTheme.pillBg,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: ZTheme.border),
                            ),
                            child: Text(
                              '${_answers.length}/${questions.length}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 12),
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
                          valueColor:
                          AlwaysStoppedAnimation<Color>(ZTheme.purple),
                        ),
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
                      ...q.optionKeys.map((key) {
                        final text = q.options[key] ?? '';
                        final isSelected = selected == key;

                        final border =
                        isSelected ? ZTheme.purple : ZTheme.border;
                        final fill =
                        isSelected ? ZTheme.selectedFill : Colors.white;

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
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900),
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
                      const SizedBox(height: 10),
                    ],
                  ),
                ),

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
                          disabledBackgroundColor:
                          ZTheme.purple.withOpacity(0.35),
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white),
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
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Review Grid: indicator cards ONLY.
/// Back button is rounded X and returns to HOME (pop until first).
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
          child: _RoundXButton(onTap: () => _goHome(context)),
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

/// Single question review.
/// AppBar back is rounded X and returns to GRID (normal back).
class QuizSingleReviewPage extends StatefulWidget {
  final List<Question> questions;
  final Map<int, String> answers;
  final int initialIndex;

  const QuizSingleReviewPage({
    super.key,
    required this.questions,
    required this.answers,
    required this.initialIndex,
  });

  @override
  State<QuizSingleReviewPage> createState() => _QuizSingleReviewPageState();
}

class _QuizSingleReviewPageState extends State<QuizSingleReviewPage> {
  late int _i;

  @override
  void initState() {
    super.initState();
    _i = widget.initialIndex.clamp(0, widget.questions.length - 1);
  }

  void _prev() {
    if (_i <= 0) return;
    setState(() => _i--);
  }

  void _next() {
    if (_i >= widget.questions.length - 1) return;
    setState(() => _i++);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final q = widget.questions[_i];
    final picked = widget.answers[_i];
    final pickedCorrect = picked != null && picked == q.answer;

    return Scaffold(
      backgroundColor: ZTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: _RoundXButton(onTap: () => Navigator.of(context).pop()),
        ),
        title: Text(
          loc.quiz_review_question_title(_i + 1, widget.questions.length),
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: pickedCorrect ? ZTheme.green : ZTheme.red,
                  width: 1.2,
                ),
                boxShadow: ZTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: pickedCorrect ? ZTheme.greenBg : ZTheme.redBg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: (pickedCorrect ? ZTheme.green : ZTheme.red)
                                .withOpacity(0.25),
                          ),
                        ),
                        child: Text(
                          'Q${_i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: pickedCorrect ? ZTheme.green : ZTheme.red,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        pickedCorrect ? Icons.check_circle : Icons.cancel,
                        color: pickedCorrect ? ZTheme.green : ZTheme.red,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    q.stem,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  ...q.optionKeys.map((key) {
                    final text = q.options[key] ?? '';
                    final isCorrect = key == q.answer;
                    final isPicked = picked == key;

                    Color border = ZTheme.border;
                    Color fill = Colors.white;

                    if (isCorrect) {
                      border = ZTheme.green;
                      fill = ZTheme.greenBg;
                    } else if (isPicked && !isCorrect) {
                      border = ZTheme.red;
                      fill = ZTheme.redBg;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900),
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
                    );
                  }),

                  if ((q.explanation ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: ZTheme.border),
                        boxShadow: ZTheme.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.quiz_explanation,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            q.explanation!.trim(),
                            style: const TextStyle(height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: integrate AI explanation here
                    },
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: Text(loc.quiz_ai_explain),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(color: ZTheme.purple.withOpacity(0.30)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _i > 0 ? _prev : null,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(
                        color: _i > 0
                            ? ZTheme.purple
                            : ZTheme.purple.withOpacity(0.25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      loc.quiz_back,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: _i > 0
                            ? ZTheme.purple
                            : ZTheme.purple.withOpacity(0.35),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _i < widget.questions.length - 1 ? _next : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ZTheme.purple,
                      disabledBackgroundColor: ZTheme.purple.withOpacity(0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      loc.quiz_next,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Result popup: removed "progress saved" block entirely.
/// Close -> back to HOME (pop quiz page).
class _ResultPopup extends StatelessWidget {
  final String title;
  final String brand;
  final int percent;
  final String correctText;

  final String correctCountLabel;
  final String correctCount;

  final String totalLabel;
  final String totalCount;

  final String reviewText;
  final String closeText;
  final String retryText;

  final VoidCallback onReview;
  final VoidCallback onClose;
  final VoidCallback onRetry;

  const _ResultPopup({
    required this.title,
    required this.brand,
    required this.percent,
    required this.correctText,
    required this.correctCountLabel,
    required this.correctCount,
    required this.totalLabel,
    required this.totalCount,
    required this.reviewText,
    required this.closeText,
    required this.retryText,
    required this.onReview,
    required this.onClose,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            blurRadius: 28,
            offset: Offset(0, 14),
            color: Color(0x24000000),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF4D8D),
                    Color(0xFF7C3AED),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.20)),
                    ),
                    child: const Icon(Icons.emoji_events_outlined,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ZTheme.bg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: ZTheme.border),
                    ),
                    child: Row(
                      children: [
                        const _PercentDonut(percent: 0, size: 0, stroke: 0),
                        _PercentDonut(percent: percent, size: 132, stroke: 14),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                brand,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF6B7280),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                correctText,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          label: correctCountLabel,
                          value: correctCount,
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          label: totalLabel,
                          value: totalCount,
                          icon: Icons.list_alt_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: onReview,
                          child: Text(
                            reviewText,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onClose,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ZTheme.purple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            closeText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onRetry,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: ZTheme.purple.withOpacity(0.30)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        retryText,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: ZTheme.purple,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded X button (for AppBar leading)
class _RoundXButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RoundXButton({required this.onTap});

  static const double _size = 36; // 👈 perfectly circular

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ZTheme.pillBg,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: _size,
          height: _size,
          child: Center(
            child: Icon(
              Icons.close,
              size: 18,
              color: Colors.black.withOpacity(0.75),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ZTheme.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ZTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ZTheme.border),
            ),
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PercentDonut extends StatelessWidget {
  final int percent;
  final double size;
  final double stroke;

  const _PercentDonut({
    required this.percent,
    required this.size,
    required this.stroke,
  });

  @override
  Widget build(BuildContext context) {
    final p = (percent.clamp(0, 100)) / 100.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _DonutPainter(
              value: p,
              stroke: stroke,
              background: const Color(0xFFEAE7FF),
              foreground: ZTheme.purple,
            ),
          ),
          Container(
            padding: const EdgeInsets.only(top: 2),
            alignment: Alignment.center,
            child: Text(
              '$percent%',
              style: const TextStyle(
                fontSize: 32,
                height: 1.0,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double value;
  final double stroke;
  final Color background;
  final Color foreground;

  _DonutPainter({
    required this.value,
    required this.stroke,
    required this.background,
    required this.foreground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide / 2) - (stroke / 2);

    final bgPaint = Paint()
      ..color = background
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi,
      false,
      bgPaint,
    );

    final sweep = (2 * pi) * value.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweep,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.stroke != stroke ||
        oldDelegate.background != background ||
        oldDelegate.foreground != foreground;
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

class ZTheme {
  static const Color bg = Color(0xFFF6F4FF);
  static const Color border = Color(0xFFE6E6E6);

  static const Color purple = Color(0xFF2C015D);
  static const Color selectedFill = Color(0xFFF1EDFF);
  static const Color pillBg = Color(0xFFF6F4FF);

  static const Color green = Color(0xFF22C55E);
  static const Color red = Color(0xFFEF4444);

  static const Color greenBg = Color(0xFFE9FBEF);
  static const Color redBg = Color(0xFFFDECEC);

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      blurRadius: 12,
      offset: Offset(0, 5),
      color: Color(0x14000000),
    ),
  ];
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
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
