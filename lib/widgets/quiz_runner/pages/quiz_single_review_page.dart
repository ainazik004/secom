// lib/widgets/quiz_runner/pages/quiz_single_review_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/question.dart';
import '../services/ai_explain_service.dart';
import '../widgets/round_x_button.dart';

// ✅ Use stacked/nested fraction renderer for comparison values
import '../widgets/comparison_value_card.dart';

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

  bool _isComparison(Question q) {
    final t = (q.topic ?? '').toLowerCase();
    return t == 'comparison' || t.startsWith('comparison/') || t.contains('/comparison');
  }

  // Removes the “Сравните значения” header inside stem (review mode).
  // Also removes lone "." so the question does not show a dot.
  String _cleanStem(String stem) {
    var s = stem.trim();

    s = s.replaceAll('Сравните значения', '').trim();
    s = s.replaceAll('Сравните значения:', '').trim();
    s = s.replaceAll('Compare values', '').trim();
    s = s.replaceAll('Compare values:', '').trim();

    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    s = s.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    s = s.trim();

    // ✅ If stem is just "." or "•" etc. treat as empty
    final onlyPunct = s.replaceAll(RegExp(r'[\s\.\u2022•·-]+'), '');
    if (onlyPunct.isEmpty) return '';

    return s;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final q = widget.questions[_i];
    final picked = widget.answers[_i] ?? '';
    final pickedCorrect = picked.isNotEmpty && picked == q.answer;
    final expl = q.explanation?.trim() ?? '';

    final isComparison = _isComparison(q);
    final left = (q.left ?? '').trim();
    final right = (q.right ?? '').trim();

    final stemClean = _cleanStem(q.stem);

    // Backgrounds
    final pageBg = cs.surface;
    final cardBg = isDark ? cs.surfaceContainerHighest : cs.surfaceContainerHigh;

    // Status colors
    const ok = Color(0xFF22C55E);
    const bad = Color(0xFFEF4444);
    final status = pickedCorrect ? ok : bad;

    final shadow = BoxShadow(
      color: cs.shadow.withOpacity(isDark ? 0.35 : 0.12),
      blurRadius: isDark ? 20 : 18,
      offset: const Offset(0, 10),
    );

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: RoundXButton(onTap: () => Navigator.of(context).pop()),
        ),
        title: Text(
          loc.quiz_review_question_title(_i + 1, widget.questions.length),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [
          // Question card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [shadow],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: status.withOpacity(isDark ? 0.22 : 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Q${_i + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: isDark ? Colors.white : status,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      pickedCorrect ? Icons.check_circle : Icons.cancel,
                      color: status,
                      size: 18,
                    ),
                  ],
                ),

                // ✅ Do not show the stem area if it became empty (prevents lone dot)
                if (stemClean.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    stemClean,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      height: 1.35,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Comparison values (left/right) with stacked fractions
          if (isComparison) ...[
            Row(
              children: [
                Expanded(
                  child: ComparisonSideCard(
                    value: left.isEmpty ? '—' : left,
                    cs: cs,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ComparisonSideCard(
                    value: right.isEmpty ? '—' : right,
                    cs: cs,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Comparison choices: show both picked and correct
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ComparisonAnswerTile(
                        letter: 'A',
                        picked: picked,
                        correct: q.answer,
                        cs: cs,
                        onTap: null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ComparisonAnswerTile(
                        letter: 'B',
                        picked: picked,
                        correct: q.answer,
                        cs: cs,
                        onTap: null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ComparisonAnswerTile(
                        letter: 'C',
                        picked: picked,
                        correct: q.answer,
                        cs: cs,
                        onTap: null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ComparisonAnswerTile(
                        letter: 'D',
                        picked: picked,
                        correct: q.answer,
                        cs: cs,
                        onTap: null,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
          ] else ...[
            // MCQ options
            ...q.optionKeys.map((key) {
              final text = (q.options[key] ?? '').toString();
              final isCorrect = key == q.answer;
              final isPicked = picked == key;

              Color fill = cardBg;
              if (isCorrect) {
                fill = ok.withOpacity(isDark ? 0.18 : 0.16);
              } else if (isPicked && !isCorrect) {
                fill = bad.withOpacity(isDark ? 0.20 : 0.14);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [shadow],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: cs.surface.withOpacity(isDark ? 0.50 : 0.85),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          key,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 2),

          // Explanation
          if (expl.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [shadow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.quiz_explanation,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    expl,
                    style: TextStyle(
                      height: 1.35,
                      color: cs.onSurface.withOpacity(0.90),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Jinny button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _openJinnyChat(context),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(color: cs.primary.withOpacity(0.25)),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icon/quokka_large.png',
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    loc.quiz_ai_explain,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Report a mistake
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openReportMistake(context),
              icon: Icon(Icons.flag_rounded, size: 18, color: cs.onSurface),
              label: Text(
                loc.report_a_mistake,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                ),
              ),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(color: cs.onSurface.withOpacity(0.18)),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Bottom navigation
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
                      color: cs.primary.withOpacity(_i > 0 ? 0.35 : 0.15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    loc.quiz_back,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: cs.primary.withOpacity(_i > 0 ? 1.0 : 0.35),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _i < widget.questions.length - 1 ? _next : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    disabledBackgroundColor: cs.primary.withOpacity(0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    loc.quiz_next,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: cs.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const SafeArea(top: false, child: SizedBox()),
        ],
      ),
    );
  }

  // -------------------- Report mistake --------------------

  Future<void> _openReportMistake(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final q = widget.questions[_i];
    final picked = widget.answers[_i] ?? '';
    final messageCtrl = TextEditingController();

    bool sending = false;

    Future<void> submit(StateSetter setModalState) async {
      final text = messageCtrl.text.trim();
      if (text.isEmpty || sending) return;

      setModalState(() => sending = true);

      try {
        final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
            .httpsCallable('submitMistakeReport');

        await callable.call(<String, dynamic>{
          'message': text,
          'questionId': q.id,
          'stem': q.stem,
          'correct': q.answer,
          'picked': picked,
          'options': q.options,
          'topic': q.topic,
          'section': q.section,
          'language': q.language,
          'left': q.left,
          'right': q.right,
          'locale': Localizations.localeOf(context).languageCode,
          'platform': Theme.of(context).platform.toString(),
        });

        if (!context.mounted) return;
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.report_sent),
            backgroundColor: cs.primary,
          ),
        );
      } on FirebaseFunctionsException catch (e) {
        setModalState(() => sending = false);
        if (!context.mounted) return;

        String msg;
        switch (e.code) {
          case 'unauthenticated':
            msg = loc.login_required;
            break;
          case 'invalid-argument':
            msg = e.message ?? loc.invalid_input;
            break;
          case 'resource-exhausted':
            msg = e.message ?? loc.daily_limit_reached;
            break;
          default:
            msg = e.message ?? '${loc.error_prefix}: ${e.code}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      } catch (e) {
        setModalState(() => sending = false);
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.error_prefix}: $e')),
        );
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (sheetCtx) {
        final bottomInset = MediaQuery.of(sheetCtx).viewInsets.bottom;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: Material(
                    color: cs.surface,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(ctx).size.height * 0.80,
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  loc.report_a_mistake,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              loc.report_hint,
                              style: TextStyle(
                                color: cs.onSurfaceVariant.withOpacity(0.85),
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: messageCtrl,
                              autofocus: true,
                              minLines: 4,
                              maxLines: 10,
                              textInputAction: TextInputAction.newline,
                              decoration: InputDecoration(
                                hintText: loc.report_placeholder,
                                filled: true,
                                fillColor: cs.surfaceContainerHighest,
                                contentPadding: const EdgeInsets.all(14),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: cs.outlineVariant.withOpacity(0.55),
                                    width: 1.2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: cs.primary.withOpacity(0.85),
                                    width: 1.6,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: sending ? null : () => submit(setModalState),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cs.primary,
                                  disabledBackgroundColor: cs.primary.withOpacity(0.35),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: Text(
                                  sending ? loc.sending : loc.send,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: cs.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SafeArea(
                              top: false,
                              child: SizedBox(height: bottomInset > 0 ? 6 : 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // -------------------- Jinny chat --------------------

  Future<void> _openJinnyChat(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;

    final q = widget.questions[_i];
    final picked = widget.answers[_i] ?? '';

    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    final language = lang.startsWith('ky') ? 'ky' : 'ru';

    final hiddenInitial = _buildHiddenInitialForJinny(
      loc: loc,
      q: q,
      picked: picked,
      language: language,
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      enableDrag: true,
      builder: (_) {
        return _BottomSheetSurface(
          child: _JinnyChatSheet(
            loc: loc,
            language: language,
            question: q,
            picked: picked,
            hiddenInitialUserMessage: hiddenInitial,
          ),
        );
      },
    );
  }

  String _buildHiddenInitialForJinny({
    required AppLocalizations loc,
    required Question q,
    required String picked,
    required String language,
  }) {
    final isComp = _isComparison(q);

    if (isComp) {
      final l = (q.left ?? '').trim();
      final r = (q.right ?? '').trim();
      final pickedLetter = picked.isEmpty ? '—' : picked;
      final correctLetter = q.answer;

      return [
        'Тип: comparison',
        'LEFT: ${l.isEmpty ? '—' : l}',
        'RIGHT: ${r.isEmpty ? '—' : r}',
        'Ответ пользователя: $pickedLetter',
        'Правильный ответ: $correctLetter',
        'Поясни, почему правильный вариант именно $correctLetter.',
      ].join('\n');
    }

    final pickedText = picked.isEmpty ? '—' : '$picked. ${q.options[picked] ?? ''}';
    final correctText = '${q.answer}. ${q.options[q.answer] ?? ''}';
    return loc.jinny_firstPrompt(pickedText, correctText);
  }
}

// -------------------- BottomSheet shell --------------------

class _BottomSheetSurface extends StatelessWidget {
  final Widget child;
  const _BottomSheetSurface({required this.child});

  @override
  Widget build(BuildContext context) => child;
}

class _ChatMsg {
  final bool fromJinny;
  final String fullText;
  int shown;

  _ChatMsg({
    required this.fromJinny,
    required this.fullText,
    this.shown = 0,
  });

  bool get done => shown >= fullText.length;

  String get visibleText {
    final end = shown.clamp(0, fullText.length);
    return fullText.substring(0, end);
  }
}

class _JinnyChatSheet extends StatefulWidget {
  final AppLocalizations loc;
  final String language;
  final Question question;
  final String picked;
  final String hiddenInitialUserMessage;

  const _JinnyChatSheet({
    required this.loc,
    required this.language,
    required this.question,
    required this.picked,
    required this.hiddenInitialUserMessage,
  });

  @override
  State<_JinnyChatSheet> createState() => _JinnyChatSheetState();
}

class _JinnyChatSheetState extends State<_JinnyChatSheet> with WidgetsBindingObserver {
  static const double _minSize = 0.40;
  static const double _halfSize = 0.60;
  static const double _maxSize = 1.00;

  final DraggableScrollableController _sheetCtrl = DraggableScrollableController();

  final List<_ChatMsg> _messages = [];
  bool _sending = false;
  bool _initialSent = false;

  final TextEditingController _inputCtrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  final Map<int, Timer> _typeTimers = {};
  bool _userInteracted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      await _sendHiddenInitialPromptOnce();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final t in _typeTimers.values) {
      t.cancel();
    }
    _typeTimers.clear();
    _sheetCtrl.dispose();
    _inputCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;
      if (bottomInset > 0 && _userInteracted) {
        _goFullscreen();
      }
    });
    super.didChangeMetrics();
  }

  Future<void> _goFullscreen() async {
    if (!_sheetCtrl.isAttached) return;
    try {
      await _sheetCtrl.animateTo(
        _maxSize,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {}
  }

  List<Map<String, String>> _buildHistory({String? userTextBeingSent}) {
    const maxHistory = 14;
    final msgs = List<_ChatMsg>.from(_messages);

    if (userTextBeingSent != null &&
        msgs.isNotEmpty &&
        msgs.last.fromJinny == false &&
        msgs.last.fullText.trim() == userTextBeingSent.trim()) {
      msgs.removeLast();
    }

    final start = (msgs.length > maxHistory) ? (msgs.length - maxHistory) : 0;
    final recent = msgs.sublist(start);

    return recent
        .where((m) => m.fullText.trim().isNotEmpty)
        .map((m) => {
      'role': m.fromJinny ? 'assistant' : 'user',
      'content': m.fullText,
    })
        .toList();
  }

  String _sanitize(String input) {
    var s = input;
    s = s.replaceAll(r'\[', '');
    s = s.replaceAll(r'\]', '');
    s = s.replaceAll(r'$$', '');
    s = s.replaceAll(r'$', '');
    s = s.replaceAll(r'\times', '×');
    s = s.replaceAll(r'\cdot', '·');
    s = s.replaceAll(r'\pi', 'π');
    s = s.replaceAll(r'\approx', '≈');
    s = s.replaceAll(r'\quad', ' ');
    s = s.replaceAll(r'\,', ' ');
    s = s.replaceAll(r'\%', '%');

    s = s.replaceAllMapped(
      RegExp(r'\\frac\{([^{}]+)\}\{([^{}]+)\}'),
          (m) => '${m.group(1)}/${m.group(2)}',
    );

    s = s.replaceAllMapped(
      RegExp(r'\\text\{([^{}]*)\}'),
          (m) => m.group(1) ?? '',
    );

    s = s.replaceAll('\\', '');
    s = s.replaceAll(RegExp(r'[ \t]+\n'), '\n');
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    s = s.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    s = s.trim();
    return s.isEmpty ? '—' : s;
  }

  void _startTypewriterForIndex(int idx, ScrollController listCtrl) {
    _typeTimers[idx]?.cancel();
    _typeTimers.remove(idx);

    if (idx < 0 || idx >= _messages.length) return;
    final msg = _messages[idx];

    if (!msg.fromJinny) {
      msg.shown = msg.fullText.length;
      return;
    }

    msg.shown = 0;

    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      if (idx < 0 || idx >= _messages.length) return;

      final t = Timer.periodic(const Duration(milliseconds: 16), (_) {
        if (!mounted) return;
        if (idx < 0 || idx >= _messages.length) {
          _typeTimers[idx]?.cancel();
          _typeTimers.remove(idx);
          return;
        }

        final m = _messages[idx];
        final next = (m.shown + 2).clamp(0, m.fullText.length);
        if (next == m.shown) return;

        setState(() => m.shown = next);

        if (listCtrl.hasClients) {
          listCtrl.animateTo(
            listCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
          );
        }

        if (m.done) {
          _typeTimers[idx]?.cancel();
          _typeTimers.remove(idx);
        }
      });

      _typeTimers[idx] = t;
    });
  }

  Future<void> _sendHiddenInitialPromptOnce() async {
    if (_initialSent) return;
    _initialSent = true;

    final text = widget.hiddenInitialUserMessage.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      final history = _buildHistory();

      final raw = await AiExplainService.chat(
        language: widget.language,
        q: widget.question,
        picked: widget.picked,
        userMessage: text,
        history: history,
      );

      if (!mounted) return;

      final cleaned = _sanitize(raw);

      setState(() {
        _sending = false;
        _messages.add(_ChatMsg(fromJinny: true, fullText: cleaned, shown: 0));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _messages.add(_ChatMsg(fromJinny: true, fullText: 'Ошибка: $e', shown: 999999));
      });
    }
  }

  Future<void> _sendUserMessage(String userText, ScrollController listCtrl) async {
    final t = userText.trim();
    if (t.isEmpty || _sending) return;

    _userInteracted = true;
    await _goFullscreen();

    setState(() {
      _sending = true;
      _messages.add(_ChatMsg(fromJinny: false, fullText: t, shown: t.length));
    });

    if (listCtrl.hasClients) {
      listCtrl.animateTo(
        listCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
      );
    }

    try {
      final history = _buildHistory(userTextBeingSent: t);

      final raw = await AiExplainService.chat(
        language: widget.language,
        q: widget.question,
        picked: widget.picked,
        userMessage: t,
        history: history,
      );

      if (!mounted) return;

      final cleaned = _sanitize(raw);

      setState(() {
        _sending = false;
        _messages.add(_ChatMsg(fromJinny: true, fullText: cleaned, shown: 0));
      });

      _startTypewriterForIndex(_messages.length - 1, listCtrl);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _messages.add(_ChatMsg(fromJinny: true, fullText: 'Ошибка: $e', shown: 999999));
      });
    }
  }

  Widget _avatar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Image.asset(
        'assets/icon/quokka_large.png',
        width: 34,
        height: 34,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _userAvatar(ColorScheme cs) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.person_rounded,
        size: 18,
        color: cs.onSurfaceVariant.withOpacity(0.75),
      ),
    );
  }

  Widget _typingBubble(ColorScheme cs, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(isDark ? 0.30 : 0.10),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(color: cs.onSurfaceVariant.withOpacity(0.65)),
          const SizedBox(width: 4),
          _Dot(delayMs: 140, color: cs.onSurfaceVariant.withOpacity(0.65)),
          const SizedBox(width: 4),
          _Dot(delayMs: 280, color: cs.onSurfaceVariant.withOpacity(0.65)),
        ],
      ),
    );
  }

  Widget _messageBubble({
    required String text,
    required bool fromJinny,
    required ColorScheme cs,
    required bool isDark,
  }) {
    final bg = fromJinny ? cs.surfaceContainerHighest : cs.primaryContainer;
    final fg = fromJinny ? cs.onSurface : cs.onPrimaryContainer;

    final shadow = BoxShadow(
      color: cs.shadow.withOpacity(isDark ? 0.30 : 0.10),
      blurRadius: 14,
      offset: const Offset(0, 8),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [shadow],
        ),
        child: Text(
          text,
          style: TextStyle(
            height: 1.35,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }

  Widget _chatRow({
    required bool isUser,
    required Widget bubble,
    required ColorScheme cs,
  }) {
    const avatarSize = 34.0;
    const gap = 10.0;

    final leftAvatar = isUser ? const SizedBox(width: avatarSize, height: avatarSize) : _avatar();
    final rightAvatar = isUser ? _userAvatar(cs) : const SizedBox(width: avatarSize, height: avatarSize);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(width: avatarSize, height: avatarSize, child: leftAvatar),
          const SizedBox(width: gap),
          Expanded(
            child: Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: bubble,
            ),
          ),
          const SizedBox(width: gap),
          SizedBox(width: avatarSize, height: avatarSize, child: rightAvatar),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final sheetBg = isDark ? cs.surfaceContainerHighest : cs.surface;
    final headerText = cs.onSurface;

    final shadow = BoxShadow(
      color: cs.shadow.withOpacity(isDark ? 0.45 : 0.16),
      blurRadius: 24,
      offset: const Offset(0, -10),
    );

    return DraggableScrollableSheet(
      controller: _sheetCtrl,
      expand: false,
      initialChildSize: _halfSize,
      minChildSize: _minSize,
      maxChildSize: _maxSize,
      builder: (ctx, sheetScrollController) {
        final listCtrl = sheetScrollController;

        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              child: Material(
                color: sheetBg,
                child: Container(
                  decoration: BoxDecoration(
                    color: sheetBg,
                    boxShadow: [shadow],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: cs.onSurfaceVariant.withOpacity(0.20),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                        child: Row(
                          children: [
                            _avatar(),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.loc.jinny,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: headerText,
                                    ),
                                  ),
                                  Text(
                                    _sending ? 'typing…' : 'online',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurfaceVariant.withOpacity(0.75),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                              color: cs.onSurface.withOpacity(0.75),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: cs.outlineVariant.withOpacity(0.35)),
                      Expanded(
                        child: ListView.builder(
                          controller: listCtrl,
                          padding: const EdgeInsets.only(top: 8, bottom: 12),
                          itemCount: _messages.length + (_sending ? 1 : 0),
                          itemBuilder: (ctx, index) {
                            if (_sending && index == _messages.length) {
                              return _chatRow(
                                isUser: false,
                                bubble: _typingBubble(cs, isDark),
                                cs: cs,
                              );
                            }

                            final m = _messages[index];
                            final isUser = !m.fromJinny;

                            if (!isUser && m.shown == 0 && m.fullText.isNotEmpty) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                _startTypewriterForIndex(index, listCtrl);
                              });
                            }

                            return _chatRow(
                              isUser: isUser,
                              cs: cs,
                              bubble: _messageBubble(
                                text: isUser ? m.fullText : m.visibleText,
                                fromJinny: !isUser,
                                cs: cs,
                                isDark: isDark,
                              ),
                            );
                          },
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          decoration: BoxDecoration(
                            color: sheetBg,
                            border: Border(
                              top: BorderSide(color: cs.outlineVariant.withOpacity(0.35)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _inputCtrl,
                                  focusNode: _focus,
                                  autofocus: false,
                                  textInputAction: TextInputAction.send,
                                  minLines: 1,
                                  maxLines: 4,
                                  onTap: () {
                                    _userInteracted = true;
                                    _goFullscreen();
                                  },
                                  onSubmitted: (_) {
                                    final text = _inputCtrl.text;
                                    _inputCtrl.clear();
                                    _sendUserMessage(text, listCtrl);
                                  },
                                  decoration: InputDecoration(
                                    hintText: widget.loc.quiz_ai_explain,
                                    hintStyle: TextStyle(
                                      color: cs.onSurfaceVariant.withOpacity(0.70),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    filled: true,
                                    fillColor: cs.surfaceContainerHighest,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(999),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: _sending
                                    ? null
                                    : () {
                                  final text = _inputCtrl.text;
                                  _inputCtrl.clear();
                                  _sendUserMessage(text, listCtrl);
                                },
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _sending ? cs.primary.withOpacity(0.35) : cs.primary,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Icon(
                                    Icons.send_rounded,
                                    color: cs.onPrimary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Dot extends StatefulWidget {
  final int delayMs;
  final Color color;

  const _Dot({
    this.delayMs = 0,
    required this.color,
  });

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _a = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (!mounted) return;
      _c.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

// -------------------- Comparison UI (review) --------------------

class _ComparisonAnswerTile extends StatelessWidget {
  final String letter;
  final String picked;
  final String correct;
  final ColorScheme cs;
  final VoidCallback? onTap;

  const _ComparisonAnswerTile({
    required this.letter,
    required this.picked,
    required this.correct,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const ok = Color(0xFF22C55E);
    const bad = Color(0xFFEF4444);

    final isCorrectTile = letter == correct;
    final isPickedTile = letter == picked;
    final isWrongPickedTile = isPickedTile && !isCorrectTile && picked.isNotEmpty;

    Color fill = cs.surfaceContainerHighest;
    if (isCorrectTile) {
      fill = ok.withOpacity(isDark ? 0.18 : 0.14);
    } else if (isWrongPickedTile) {
      fill = bad.withOpacity(isDark ? 0.20 : 0.14);
    }

    final emphasizedFill = isPickedTile
        ? Color.alphaBlend(cs.primary.withOpacity(isDark ? 0.16 : 0.10), fill)
        : fill;

    IconData? badge;
    Color? badgeColor;
    if (isCorrectTile) {
      badge = Icons.check_circle_rounded;
      badgeColor = ok;
    } else if (isWrongPickedTile) {
      badge = Icons.cancel_rounded;
      badgeColor = bad;
    }

    final shadow = [
      BoxShadow(
        color: cs.shadow.withOpacity(isDark ? 0.14 : 0.10),
        blurRadius: 14,
        offset: const Offset(0, 10),
      ),
    ];

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        height: 72,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: emphasizedFill,
            borderRadius: BorderRadius.circular(18),
            boxShadow: shadow,
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: isPickedTile ? cs.primary : cs.onSurface,
                  ),
                ),
              ),
              if (badge != null)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Icon(badge, size: 18, color: badgeColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
