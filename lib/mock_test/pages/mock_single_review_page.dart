// lib/mock_test/pages/mock_single_review_page.dart
import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';

import '../mock_question_loader.dart';
import '../../widgets/quiz_runner/widgets/comparison_value_card.dart';
import '../../widgets/quiz_runner/widgets/round_x_button.dart';

class MockSingleReviewPage extends StatefulWidget {
  final List<MockQuestion> questions;
  final Map<int, String> answers;
  final int initialIndex;

  const MockSingleReviewPage({
    super.key,
    required this.questions,
    required this.answers,
    required this.initialIndex,
  });

  @override
  State<MockSingleReviewPage> createState() => _MockSingleReviewPageState();
}

class _MockSingleReviewPageState extends State<MockSingleReviewPage> {
  late int _i;

  // Cache Jinny explanation per question+language+endpoint to reduce API load.
  final Map<String, String> _jinnyCache = {};

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

  // ---------- helpers (null-safe / defensive) ----------

  String _s(dynamic v) => (v == null) ? '' : v.toString();

  bool _looksComparison(MockQuestion q) {
    final t = _s(q.topic).toLowerCase().trim();
    if (t == 'comparison' || t.startsWith('comparison/') || t.contains('/comparison')) return true;

    // Some datasets don’t set topic but still have left/right values.
    final l = _s(q.left).trim();
    final r = _s(q.right).trim();
    return l.isNotEmpty || r.isNotEmpty;
  }

  String _cleanStem(String stem) {
    var s = stem.trim();

    s = s.replaceAll('Сравните значения', '').trim();
    s = s.replaceAll('Сравните значения:', '').trim();
    s = s.replaceAll('Compare values', '').trim();
    s = s.replaceAll('Compare values:', '').trim();

    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    s = s.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    s = s.trim();

    final onlyPunct = s.replaceAll(RegExp(r'[\s\.\u2022•·-]+'), '');
    if (onlyPunct.isEmpty) return '';

    return s;
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final q = widget.questions[_i];
    final picked = widget.answers[_i] ?? '';
    final pickedCorrect = picked.isNotEmpty && picked == _s(q.answer);
    final expl = _s(q.explanation).trim();

    final isComparison = _looksComparison(q);
    final left = _s(q.left).trim();
    final right = _s(q.right).trim();

    final stemClean = _cleanStem(_s(q.stem));

    final pageBg = cs.surface;
    final cardBg = isDark ? cs.surfaceContainerHighest : cs.surfaceContainerHigh;

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
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [
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
                    Icon(pickedCorrect ? Icons.check_circle : Icons.cancel, color: status, size: 18),
                  ],
                ),
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

          if (isComparison) ...[
            Row(
              children: [
                Expanded(child: ComparisonSideCard(value: left.isEmpty ? '—' : left, cs: cs)),
                const SizedBox(width: 12),
                Expanded(child: ComparisonSideCard(value: right.isEmpty ? '—' : right, cs: cs)),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _ComparisonAnswerTile(letter: 'A', picked: picked, correct: _s(q.answer), cs: cs, onTap: null)),
                    const SizedBox(width: 12),
                    Expanded(child: _ComparisonAnswerTile(letter: 'B', picked: picked, correct: _s(q.answer), cs: cs, onTap: null)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _ComparisonAnswerTile(letter: 'C', picked: picked, correct: _s(q.answer), cs: cs, onTap: null)),
                    const SizedBox(width: 12),
                    Expanded(child: _ComparisonAnswerTile(letter: 'D', picked: picked, correct: _s(q.answer), cs: cs, onTap: null)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
          ] else ...[
            ...q.optionKeys.map((key) {
              final text = _s(q.options[key]);
              final isCorrect = key == _s(q.answer);
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
                          style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface),
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
                  Text(loc.quiz_explanation, style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface)),
                  const SizedBox(height: 8),
                  Text(expl, style: TextStyle(height: 1.35, color: cs.onSurface.withOpacity(0.90))),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _openJinnyChat(context),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: cs.primary.withOpacity(0.25)),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/icon/quokka_large.png', width: 18, height: 18, fit: BoxFit.contain),
                  const SizedBox(width: 10),
                  Text(loc.quiz_ai_explain, style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openReportMistake(context),
              icon: Icon(Icons.flag_rounded, size: 18, color: cs.onSurface),
              label: Text(loc.report_a_mistake, style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface)),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: cs.onSurface.withOpacity(0.18)),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _i > 0 ? _prev : null,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(color: cs.primary.withOpacity(_i > 0 ? 0.35 : 0.15)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(loc.quiz_next, style: TextStyle(fontWeight: FontWeight.w900, color: cs.onPrimary)),
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
        final callable = FirebaseFunctions.instanceFor(region: 'europe-west1').httpsCallable('submitMistakeReport');

        await callable.call(<String, dynamic>{
          'message': text,
          'questionId': _s(q.id),
          'stem': _s(q.stem),
          'correct': _s(q.answer),
          'picked': picked,
          'options': q.options,
          'topic': _s(q.topic),
          'section': _s(q.section),
          'language': _s(q.language),
          'left': _s(q.left),
          'right': _s(q.right),
          'value1': _s(q.left),
          'value2': _s(q.right),
          'locale': Localizations.localeOf(context).languageCode,
          'platform': Theme.of(context).platform.toString(),
          'source': 'mock',
        });

        if (!context.mounted) return;
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.report_sent), backgroundColor: cs.primary),
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

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      } catch (e) {
        setModalState(() => sending = false);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.error_prefix}: $e')));
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
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.80),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(loc.report_a_mistake, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: cs.onSurface)),
                                const Spacer(),
                                IconButton(onPressed: () => Navigator.of(ctx).pop(), icon: const Icon(Icons.close_rounded)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              loc.report_hint,
                              style: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.85), fontWeight: FontWeight.w600, height: 1.35),
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
                                  borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.55), width: 1.2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: cs.primary.withOpacity(0.85), width: 1.6),
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: Text(
                                  sending ? loc.sending : loc.send,
                                  style: TextStyle(fontWeight: FontWeight.w900, color: cs.onPrimary),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SafeArea(top: false, child: SizedBox(height: bottomInset > 0 ? 6 : 0)),
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

  // -------------------- Jinny (make backend receive EVERYTHING) --------------------
  //
  // The backend can be strict (e.g., expects question OR value1/value2 at top-level).
  // This call sends:
  // - question (full object)
  // - questionData / problem (aliases)
  // - left/right + value1/value2 both inside question and at top-level
  // - stem/answer/options also at top-level (aliases)
  //
  // This prevents “Missing question” and prevents Jinny from asking you to type fractions.

  Future<String> _callJinny({
    required String language,
    required MockQuestion q,
    required String picked,
    required String userMessage,
  }) async {
    final section = _s(q.section).toLowerCase();
    final isComp = _looksComparison(q);

    final callableName = isComp
        ? 'aiExplainComparison'
        : (section.contains('math')
        ? 'aiExplainMath'
        : (section.contains('analogy') ? 'aiExplainAnalogy' : 'aiExplainLanguage'));

    final callable = FirebaseFunctions.instanceFor(region: 'europe-west1').httpsCallable(callableName);

    final left = _s(q.left).trim();
    final right = _s(q.right).trim();

    final questionPayload = <String, dynamic>{
      'id': _s(q.id),
      'stem': _s(q.stem),
      'answer': _s(q.answer),
      'options': q.options,
      'topic': _s(q.topic),
      'section': _s(q.section),
      'language': _s(q.language),
      'left': left,
      'right': right,
      'value1': left,
      'value2': right,
      'explanation': _s(q.explanation),
      'isComparison': isComp,
    };

    final payload = <String, dynamic>{
      // Original keys (what your functions likely expect)
      'language': language,
      'picked': picked,
      'userMessage': userMessage,
      'history': const [],
      'question': questionPayload,

      // Aliases (for any older/newer backend variants)
      'questionData': questionPayload,
      'problem': questionPayload,

      // Top-level fallbacks (some backends validate these instead of question.*)
      'id': _s(q.id),
      'stem': _s(q.stem),
      'answer': _s(q.answer),
      'options': q.options,
      'topic': _s(q.topic),
      'section': _s(q.section),
      'questionSection': _s(q.section),
      'languageCode': _s(q.language),

      'left': left,
      'right': right,
      'value1': left,
      'value2': right,

      'isComparison': isComp,
      'source': 'mock',
    };

    final res = await callable.call(payload);

    final data = res.data;
    if (data is Map) {
      if (data['text'] != null) return data['text'].toString();
      if (data['answer'] != null) return data['answer'].toString();
      if (data['result'] != null) return data['result'].toString();
      return data.toString();
    }
    if (data is String) return data;
    return data?.toString() ?? '—';
  }

  Future<void> _openJinnyChat(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;

    final q = widget.questions[_i];
    final picked = widget.answers[_i] ?? '';

    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    final language = lang.startsWith('ky') ? 'ky' : 'ru';

    final isComp = _looksComparison(q);
    final endpoint = isComp ? 'comparison' : _s(q.section);

    final cacheKey = '${_s(q.id)}|$language|$endpoint|${_s(q.topic)}';
    final cached = _jinnyCache[cacheKey];

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
          child: _JinnyExplainSheet(
            loc: loc,
            language: language,
            question: q,
            picked: picked,
            hiddenInitialUserMessage: hiddenInitial,
            cachedResponse: cached,
            onCache: (text) => _jinnyCache[cacheKey] = text,
            callJinny: _callJinny,
          ),
        );
      },
    );
  }

  String _buildHiddenInitialForJinny({
    required AppLocalizations loc,
    required MockQuestion q,
    required String picked,
    required String language,
  }) {
    final isComp = _looksComparison(q);
    final left = _s(q.left).trim();
    final right = _s(q.right).trim();

    final rulesRu = [
      'Поясни решение понятно и не слишком коротко.',
      'Формат:',
      '• Можно использовать 0–3 заголовка строками начиная с "## " (не обязательно).',
      '• Пункты начинай с "• ".',
      '• Между смысловыми блоками делай 1 пустую строку.',
      '• НЕ делай пустую строку сразу после заголовка "## ...".',
      '• Дроби только как a/b, степени как x^2, без LaTeX.',
    ].join('\n');

    final rulesKy = [
      'Түшүндүрмө түшүнүктүү жана өтө кыска эмес болсун.',
      'Формат:',
      '• 0–3 "## " заголовок колдонсо болот (милдеттүү эмес).',
      '• Пункттар "• " менен башталсын.',
      '• Маанилүү блоктордун ортосунда 1 бош сап болсун.',
      '• "## ..." заголовоктон кийин дароо бош сап койбо.',
      '• Дробь a/b, даража x^2, LaTeX жок.',
    ].join('\n');

    final rules = language == 'ky' ? rulesKy : rulesRu;

    if (isComp) {
      final pickedLetter = picked.isEmpty ? '—' : picked;
      final correctLetter = _s(q.answer);

      return [
        rules,
        '',
        'Тип: comparison',
        'Колонка A (value1): ${left.isEmpty ? '—' : left}',
        'Колонка B (value2): ${right.isEmpty ? '—' : right}',
        'Ответ пользователя: $pickedLetter',
        'Правильный ответ: $correctLetter',
        'ВАЖНО: значения уже даны. НЕ проси пользователя вводить дроби/числа. Просто сравни Колонку A и Колонку B.',
        'Объясни, почему правильный код ($correctLetter) верный.',
      ].join('\n');
    }

    final pickedText = picked.isEmpty ? '—' : '$picked. ${q.options[picked] ?? ''}';
    final correctText = '${_s(q.answer)}. ${q.options[_s(q.answer)] ?? ''}';

    return [
      rules,
      '',
      loc.jinny_firstPrompt(pickedText, correctText),
      '',
      'Поясни именно эту задачу (не общими фразами). Если выбран неверно — покажи где ошибка.',
    ].join('\n');
  }
}

class _BottomSheetSurface extends StatelessWidget {
  final Widget child;
  const _BottomSheetSurface({required this.child});

  @override
  Widget build(BuildContext context) => child;
}

class _JinnyExplainSheet extends StatefulWidget {
  final AppLocalizations loc;
  final String language;
  final MockQuestion question;
  final String picked;

  final String hiddenInitialUserMessage;
  final String? cachedResponse;
  final void Function(String text) onCache;

  final Future<String> Function({
  required String language,
  required MockQuestion q,
  required String picked,
  required String userMessage,
  }) callJinny;

  const _JinnyExplainSheet({
    required this.loc,
    required this.language,
    required this.question,
    required this.picked,
    required this.hiddenInitialUserMessage,
    required this.cachedResponse,
    required this.onCache,
    required this.callJinny,
  });

  @override
  State<_JinnyExplainSheet> createState() => _JinnyExplainSheetState();
}

class _JinnyExplainSheetState extends State<_JinnyExplainSheet> {
  static const double _minSize = 0.40;
  static const double _halfSize = 0.60;
  static const double _maxSize = 1.00;

  final DraggableScrollableController _sheetCtrl = DraggableScrollableController();

  bool _loading = false;

  String _fullText = '';
  List<_TwUnit> _units = const [];
  int _shownUnits = 0;
  Timer? _typeTimer;

  DateTime _lastAutoScroll = DateTime.fromMillisecondsSinceEpoch(0);
  bool _userIsScrollingList = false;

  @override
  void initState() {
    super.initState();

    final cached = widget.cachedResponse?.trim();
    if (cached != null && cached.isNotEmpty) {
      _fullText = cached;
      _units = _tokenizeToUnits(_fullText);
      _shownUnits = 0;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _fetchOnce();
    });
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _sheetCtrl.dispose();
    super.dispose();
  }

  bool _isNearBottom(ScrollController c, {double threshold = 120}) {
    if (!c.hasClients) return false;
    final pos = c.position;
    return (pos.maxScrollExtent - pos.pixels) <= threshold;
  }

  void _maybeAutoScroll(ScrollController c) {
    if (!c.hasClients) return;
    if (_userIsScrollingList) return;
    if (!_isNearBottom(c)) return;

    final now = DateTime.now();
    if (now.difference(_lastAutoScroll).inMilliseconds < 120) return;
    _lastAutoScroll = now;

    c.jumpTo(c.position.maxScrollExtent);
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

    s = s.replaceAll('\r\n', '\n');
    s = s.replaceAll(RegExp(r'[ \t]+\n'), '\n');
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    s = s.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    s = s.trim();

    return s.isEmpty ? '—' : s;
  }

  String _formatForReading(String input) {
    var s = input.trim();
    s = s.replaceAll('\r\n', '\n');

    s = s.replaceAllMapped(
      RegExp(r'(^|\n)\s*(Идея|Решение|Ответ|Проверка|Правило|Применение|Связь|Вывод|Итог)\s*(?=\n)', caseSensitive: false),
          (m) => '${m.group(1)}## ${m.group(2)}',
    );

    s = s.replaceAllMapped(
      RegExp(r'(^|\n)\s*(Ответ|Вывод|Итог|Решение|Проверка|Идея|Conclusion|Answer)\s*:\s*', caseSensitive: false),
          (m) => '${m.group(1)}## ${m.group(2)}\n',
    );

    s = s.replaceAllMapped(RegExp(r'(^|\n)\s*-\s+'), (m) => '${m.group(1)}• ');
    s = s.replaceAllMapped(RegExp(r'(^|\n)\s*•\s+'), (m) => '${m.group(1)}• ');

    s = s.replaceAllMapped(RegExp(r'(^|\n)\s*(\d+)\s*[\.\)]\s+'), (m) => '${m.group(1)}• ${m.group(2)}. ');

    s = s.replaceAllMapped(
      RegExp(r'(\b[0-9A-Za-zА-Яа-яπ]+|\))\s*\^\s*([0-9]+)\b'),
          (m) => '${m.group(1)}[[SUP:${m.group(2)}]]',
    );

    s = s.replaceAllMapped(
      RegExp(r'(?<!:)(?<!\w)(-?[0-9A-Za-zА-Яа-я]+)\s*/\s*(-?[0-9A-Za-zА-Яа-я]+)(?!\w)'),
          (m) => '[[FRAC:${m.group(1)}|${m.group(2)}]]',
    );

    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();

    s = s.replaceAllMapped(RegExp(r'(^|\n)(##[^\n]+)\n\s*\n+'), (m) => '${m.group(1)}${m.group(2)}\n');

    s = _normalizeBlockSpacing(s);
    return s.isEmpty ? '—' : s;
  }

  static String _normalizeBlockSpacing(String s) {
    final lines = s.split('\n');
    final out = <String>[];

    bool prevWasHeader = false;
    bool prevWasBullet = false;
    bool prevWasEmpty = false;

    bool isHeader(String line) => line.trimLeft().startsWith('## ');
    bool isBullet(String line) => line.trimLeft().startsWith('• ');

    for (final raw in lines) {
      final line = raw.trimRight();

      final empty = line.trim().isEmpty;
      final header = isHeader(line);
      final bullet = isBullet(line);

      if (empty) {
        if (prevWasHeader) {
          prevWasEmpty = false;
          continue;
        }
        if (prevWasEmpty) continue;
        if (prevWasBullet) continue;

        out.add('');
        prevWasEmpty = true;
        prevWasHeader = false;
        prevWasBullet = false;
        continue;
      }

      if (header && out.isNotEmpty) {
        final last = out.last;
        if (last.trim().isNotEmpty) out.add('');
      }

      if (bullet && out.isNotEmpty && !prevWasEmpty && !prevWasBullet && !prevWasHeader) {
        out.add('');
      }

      out.add(line);

      prevWasEmpty = false;
      prevWasHeader = header;
      prevWasBullet = bullet;
    }

    while (out.isNotEmpty && out.last.trim().isEmpty) {
      out.removeLast();
    }

    return out.join('\n');
  }

  List<_TwUnit> _tokenizeToUnits(String formatted) {
    final units = <_TwUnit>[];
    final re = RegExp(r'\[\[(FRAC|SUP):([^\]]+)\]\]');

    int i = 0;
    for (final m in re.allMatches(formatted)) {
      if (m.start > i) {
        units.add(_TwUnit.text(formatted.substring(i, m.start)));
      }

      final kind = m.group(1) ?? '';
      final payload = m.group(2) ?? '';

      if (kind == 'FRAC') {
        final parts = payload.split('|');
        final num = parts.isNotEmpty ? parts[0].trim() : '';
        final den = parts.length > 1 ? parts[1].trim() : '';
        units.add(_TwUnit.frac(num, den));
      } else if (kind == 'SUP') {
        units.add(_TwUnit.sup(payload.trim()));
      } else {
        units.add(_TwUnit.text(m.group(0) ?? ''));
      }

      i = m.end;
    }

    if (i < formatted.length) {
      units.add(_TwUnit.text(formatted.substring(i)));
    }

    final exploded = <_TwUnit>[];

    for (final u in units) {
      if (u.kind == _TwKind.frac) {
        final num = u.num.trim();
        final den = u.den.trim();

        final numLen = num.replaceAll(RegExp(r'\s+'), '').length;
        final denLen = den.replaceAll(RegExp(r'\s+'), '').length;

        final tooLarge = numLen > 3 || denLen > 3;

        if (tooLarge) {
          exploded.add(_TwUnit.text('${num.isEmpty ? '—' : num}/${den.isEmpty ? '—' : den}'));
        } else {
          exploded.add(u);
        }
        continue;
      }

      if (u.kind == _TwKind.sup) {
        exploded.add(u);
        continue;
      }

      final t = u.text;
      if (t.isEmpty) continue;

      final parts = _splitTextForTypewriter(t);
      for (final p in parts) {
        exploded.add(_TwUnit.text(p));
      }
    }

    return exploded.isEmpty ? <_TwUnit>[_TwUnit.text('—')] : exploded;
  }

  static List<String> _splitTextForTypewriter(String s) {
    final out = <String>[];
    final re = RegExp(r'\n|[ \t]+|[^\s]+');
    for (final m in re.allMatches(s)) {
      out.add(m.group(0)!);
    }
    return out;
  }

  List<_TwUnit> get _visibleUnits {
    final count = _shownUnits.clamp(0, _units.length);
    return _units.take(count).toList(growable: false);
  }

  Future<void> _fetchOnce() async {
    final prompt = widget.hiddenInitialUserMessage.trim();
    if (prompt.isEmpty) {
      setState(() {
        _fullText = '—';
        _units = _tokenizeToUnits(_fullText);
        _shownUnits = 0;
      });
      return;
    }

    setState(() => _loading = true);

    try {
      final raw = await widget.callJinny(
        language: widget.language,
        q: widget.question,
        picked: widget.picked,
        userMessage: prompt,
      );

      if (!mounted) return;

      final cleaned = _sanitize(raw);
      String formatted = _formatForReading(cleaned);

      final isKy = widget.language.toLowerCase().startsWith('ky');
      final a = isKy ? 'А Колонкасы' : 'Колонка А';
      final b = isKy ? 'Б Колонкасы' : 'Колонка Б';

      formatted = formatted
          .replaceAll('value1', a)
          .replaceAll('Value1', a)
          .replaceAll('VALUE1', a)
          .replaceAll('value2', b)
          .replaceAll('Value2', b)
          .replaceAll('VALUE2', b);

      setState(() {
        _loading = false;
        _fullText = formatted;
        _units = _tokenizeToUnits(_fullText);
        _shownUnits = 0;
      });

      widget.onCache(formatted);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _fullText = 'Ошибка: $e';
        _units = _tokenizeToUnits(_fullText);
        _shownUnits = _units.length;
      });
    }
  }

  void _startTypewriter(ScrollController listCtrl) {
    _typeTimer?.cancel();

    if (_units.isEmpty) return;
    if (_shownUnits >= _units.length) return;

    Future.delayed(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      if (_shownUnits >= _units.length) return;

      const tick = Duration(milliseconds: 33);

      _typeTimer = Timer.periodic(tick, (_) {
        if (!mounted) return;

        final next = (_shownUnits + 4).clamp(0, _units.length);
        if (next == _shownUnits) return;

        setState(() => _shownUnits = next);

        _maybeAutoScroll(listCtrl);

        if (_shownUnits >= _units.length) {
          _typeTimer?.cancel();
          _typeTimer = null;

          if (listCtrl.hasClients) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (listCtrl.hasClients) {
                listCtrl.jumpTo(listCtrl.position.maxScrollExtent);
              }
            });
          }
        }
      });
    });
  }

  Widget _avatar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Image.asset('assets/icon/quokka_large.png', width: 34, height: 34, fit: BoxFit.cover),
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
    required List<InlineSpan> spans,
    required ColorScheme cs,
    required bool isDark,
  }) {
    final bg = cs.surfaceContainerHighest;

    final shadow = BoxShadow(
      color: cs.shadow.withOpacity(isDark ? 0.30 : 0.10),
      blurRadius: 14,
      offset: const Offset(0, 8),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [shadow],
        ),
        child: RichText(
          text: TextSpan(children: spans),
          textAlign: TextAlign.start,
          textScaler: MediaQuery.textScalerOf(context),
        ),
      ),
    );
  }

  Widget _chatRow({required Widget bubble}) {
    const avatarSize = 34.0;
    const gap = 10.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(width: avatarSize, height: avatarSize, child: _avatar()),
          const SizedBox(width: gap),
          Expanded(child: Align(alignment: Alignment.centerLeft, child: bubble)),
          const SizedBox(width: gap),
          const SizedBox(width: avatarSize, height: avatarSize),
        ],
      ),
    );
  }

  List<InlineSpan> _buildSpans({
    required List<_TwUnit> visibleUnits,
    required TextStyle baseStyle,
    required TextStyle headerStyle,
    required ColorScheme cs,
  }) {
    final lines = <List<_TwUnit>>[[]];
    for (final u in visibleUnits) {
      if (u.kind == _TwKind.text && u.text.contains('\n')) {
        final parts = u.text.split('\n');
        for (int i = 0; i < parts.length; i++) {
          if (parts[i].isNotEmpty) lines.last.add(_TwUnit.text(parts[i]));
          if (i != parts.length - 1) lines.add([]);
        }
      } else {
        lines.last.add(u);
      }
    }

    final spans = <InlineSpan>[];

    for (int li = 0; li < lines.length; li++) {
      final lineUnits = lines[li];
      final leadingText = _collectLeadingText(lineUnits);
      final isHeader = leadingText.startsWith('## ');

      final lineStyle = isHeader ? headerStyle : baseStyle;
      bool headerPrefixRemoved = false;

      for (final u in lineUnits) {
        if (u.kind == _TwKind.text) {
          var t = u.text;

          if (isHeader && !headerPrefixRemoved) {
            if (t.startsWith('## ')) {
              t = t.substring(3);
              headerPrefixRemoved = true;
            } else {
              t = _stripHeaderPrefixIncremental(t, onStripped: () => headerPrefixRemoved = true);
            }
          }

          if (t.isNotEmpty) spans.add(TextSpan(text: t, style: lineStyle));
        } else if (u.kind == _TwKind.frac) {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: _InlineFraction(
                numerator: u.num,
                denominator: u.den,
                color: lineStyle.color ?? cs.onSurface,
                fontSize: lineStyle.fontSize ?? 14,
              ),
            ),
          );
        } else if (u.kind == _TwKind.sup) {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.top,
              child: Transform.translate(
                offset: const Offset(0, -6),
                child: Text(
                  u.sup,
                  style: lineStyle.copyWith(
                    fontSize: (lineStyle.fontSize ?? 14) * 0.70,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }
      }

      if (li != lines.length - 1) spans.add(TextSpan(text: '\n', style: baseStyle));
    }

    return spans;
  }

  static String _collectLeadingText(List<_TwUnit> units) {
    final sb = StringBuffer();
    for (final u in units) {
      if (u.kind != _TwKind.text) break;
      sb.write(u.text);
      if (sb.length >= 3) break;
    }
    return sb.toString();
  }

  static String _stripHeaderPrefixIncremental(String t, {required VoidCallback onStripped}) {
    if (t.isEmpty) return t;
    if (t.startsWith('## ')) {
      onStripped();
      return t.substring(3);
    }
    if (t.startsWith('##')) return t.substring(2);
    if (t.startsWith('# ')) return t.substring(2);
    if (t.startsWith('#')) return t.substring(1);
    return t;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sheetBg = isDark ? cs.surfaceContainerHighest : cs.surface;
    final headerText = cs.onSurface;

    final shadow = BoxShadow(
      color: cs.shadow.withOpacity(isDark ? 0.45 : 0.16),
      blurRadius: 24,
      offset: const Offset(0, -10),
    );

    final baseStyle = TextStyle(height: 1.38, fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface);

    final headerStyle = baseStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w900, height: 1.18);

    return DraggableScrollableSheet(
      controller: _sheetCtrl,
      expand: false,
      initialChildSize: _halfSize,
      minChildSize: _minSize,
      maxChildSize: _maxSize,
      builder: (ctx, sheetScrollController) {
        final listCtrl = sheetScrollController;

        if (!_loading && _units.isNotEmpty && _shownUnits == 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _startTypewriter(listCtrl);
          });
        }

        final spans = _buildSpans(visibleUnits: _visibleUnits, baseStyle: baseStyle, headerStyle: headerStyle, cs: cs);

        return Align(
          alignment: Alignment.bottomCenter,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: Material(
              color: sheetBg,
              child: Container(
                decoration: BoxDecoration(color: sheetBg, boxShadow: [shadow]),
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
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: headerText),
                                ),
                                Text(
                                  _loading ? 'typing…' : 'online',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
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
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (n) {
                          if (n is ScrollStartNotification) {
                            _userIsScrollingList = true;
                          } else if (n is ScrollEndNotification) {
                            _userIsScrollingList = false;
                          } else if (n is UserScrollNotification) {
                            _userIsScrollingList = n.direction != ScrollDirection.idle;
                          }
                          return false;
                        },
                        child: ListView(
                          controller: listCtrl,
                          padding: const EdgeInsets.only(top: 8, bottom: 12),
                          children: [
                            if (_loading && _units.isEmpty)
                              _chatRow(bubble: _typingBubble(cs, isDark))
                            else
                              _chatRow(
                                bubble: _messageBubble(
                                  spans: spans.isEmpty ? <InlineSpan>[TextSpan(text: '—', style: baseStyle)] : spans,
                                  cs: cs,
                                  isDark: isDark,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SafeArea(top: false, child: SizedBox(height: 6)),
                  ],
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

  const _Dot({this.delayMs = 0, required this.color});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _a = Tween<double>(begin: 0.25, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

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
        decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

enum _TwKind { text, frac, sup }

class _TwUnit {
  final _TwKind kind;
  final String text;
  final String num;
  final String den;
  final String sup;

  const _TwUnit._({required this.kind, this.text = '', this.num = '', this.den = '', this.sup = ''});

  factory _TwUnit.text(String t) => _TwUnit._(kind: _TwKind.text, text: t);
  factory _TwUnit.frac(String n, String d) => _TwUnit._(kind: _TwKind.frac, num: n, den: d);
  factory _TwUnit.sup(String s) => _TwUnit._(kind: _TwKind.sup, sup: s);
}

class _InlineFraction extends StatelessWidget {
  final String numerator;
  final String denominator;
  final Color color;
  final double fontSize;

  const _InlineFraction({
    required this.numerator,
    required this.denominator,
    required this.color,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final num = numerator.isEmpty ? '—' : numerator;
    final den = denominator.isEmpty ? '—' : denominator;

    final textStyle = TextStyle(
      fontSize: fontSize * 0.90,
      fontWeight: FontWeight.w800,
      color: color,
      height: 1.0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(num, style: textStyle),
          Container(
            width: (fontSize * 1.2).clamp(10.0, 40.0),
            height: 1.2,
            margin: const EdgeInsets.symmetric(vertical: 1),
            decoration: BoxDecoration(
              color: color.withOpacity(0.75),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Text(den, style: textStyle),
        ],
      ),
    );
  }
}

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

    final emphasizedFill = isPickedTile ? Color.alphaBlend(cs.primary.withOpacity(isDark ? 0.16 : 0.10), fill) : fill;

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
