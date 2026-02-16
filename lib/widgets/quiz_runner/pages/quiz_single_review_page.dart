// lib/widgets/quiz_runner/pages/quiz_single_review_page.dart
import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../currency/currency_gate.dart';

import '../models/question.dart';
import '../widgets/comparison_value_card.dart';
import '../widgets/round_x_button.dart';

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

// -------------------- AI explain pricing config models/helpers --------------------

class AiExplainCfg {
  final bool enabled;
  final int cost;
  final String title;
  const AiExplainCfg({
    required this.enabled,
    required this.cost,
    required this.title,
  });
}

class _QuizSingleReviewPageState extends State<QuizSingleReviewPage> {
  String _jinnyCacheKey({
    required String language,
    required Question q,
    required String picked,
  }) {
    final fn = _callableNameForQuestion(q);
    return '${q.id}|$language|$fn|${q.topic ?? ''}|$picked';
  }

  bool _aiBusy = false;
  // Firestore action key (must match pricing doc: actions.ai_explain)
  static const String _kActionAiExplain = 'ai_explain';

  String _aiIdempotencyKey({
    required String qid,
    required String language,
  }) =>
      'ai_explain_${language}_$qid';

  Future<void> _runAiExplainNoConfirm({
    required BuildContext context,
    required CurrencyGate gate,
    required String questionId,
    required String language,
    required Future<void> Function() onAllowed,
  }) async {

    if (!gate.canAffordNow(_kActionAiExplain)) {
      await gate.showNotEnoughPaywall(context, actionKey: _kActionAiExplain);
      return;
    }

    try {
      await gate.spend(
        actionKey: _kActionAiExplain,
        ref: 'ai_explain:$questionId',
        idempotencyKey: _aiIdempotencyKey(qid: questionId, language: language),
      );

      await onAllowed();
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition' && e.message == 'NOT_ENOUGH_ZHALBYRAKS') {
        await gate.showNotEnoughPaywall(context, actionKey: _kActionAiExplain);
        return;
      }
      rethrow;
    }
  }

  // -------------------- AI explain pricing config (Firestore: config/pricing) --------------------

  static const String _kPricingCol = 'config';
  static const String _kPricingDoc = 'pricing';

  Future<Map<String, dynamic>?> _fetchPricingDoc() async {
    final snap = await FirebaseFirestore.instance
        .collection(_kPricingCol)
        .doc(_kPricingDoc)
        .get();
    return snap.data();
  }

  String _pickLocalizedFromMap(dynamic v, String langCode) {
    if (v is Map) {
      final exact = v[langCode];
      if (exact != null && exact.toString().trim().isNotEmpty) {
        return exact.toString().trim();
      }

      final ru = v['ru'];
      if (ru != null && ru.toString().trim().isNotEmpty) return ru.toString().trim();

      final ky = v['ky'];
      if (ky != null && ky.toString().trim().isNotEmpty) return ky.toString().trim();

      final en = v['en'];
      if (en != null && en.toString().trim().isNotEmpty) return en.toString().trim();

      for (final e in v.entries) {
        final s = e.value?.toString() ?? '';
        if (s.trim().isNotEmpty) return s.trim();
      }
    }
    return '';
  }

  Future<AiExplainCfg> _loadAiExplainCfg(AppLocalizations loc) async {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();

    final data = await _fetchPricingDoc();

    final actions = (data?['actions'] is Map) ? (data!['actions'] as Map) : const {};
    final ai = (actions['ai_explain'] is Map) ? (actions['ai_explain'] as Map) : const {};

    final enabledRaw = ai['enabled'];
    final costRaw = ai['cost'];
    final titleRaw = ai['title'];

    final enabled = enabledRaw is bool ? enabledRaw : true;

    int cost = 0;
    if (costRaw is int) cost = costRaw;
    if (costRaw is num) cost = costRaw.toInt();

    final pickedTitle = _pickLocalizedFromMap(titleRaw, lang);
    final title = pickedTitle.isNotEmpty ? pickedTitle : loc.quiz_ai_explain;

    return AiExplainCfg(enabled: enabled, cost: cost, title: title);
  }

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

  bool _isComparison(Question q) {
    final t = (q.topic ?? '').toLowerCase();
    return t == 'comparison' || t.startsWith('comparison/') || t.contains('/comparison');
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

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      } catch (e) {
        setModalState(() => sending = false);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${loc.error_prefix}: $e')));
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

  // -------------------- Jinny (FIXED payload for your Cloud Functions) --------------------

  String _callableNameForQuestion(Question q) {
    if (_isComparison(q)) return 'aiExplainComparison';

    final s = (q.section ?? '').toLowerCase();
    if (s.contains('math')) return 'aiExplainMath';
    if (s.contains('analogy')) return 'aiExplainAnalogy';
    return 'aiExplainLanguage';
  }

  Future<String> _callJinnyOnce({
    required String language,
    required Question q,
    required String picked,
  }) async {
    final fn = _callableNameForQuestion(q);

    // Your backend cache key uses picked; keep stable and short here too.
    final cacheKey = _jinnyCacheKey(language: language, q: q, picked: picked);
    final cached = _jinnyCache[cacheKey];
    if (cached != null && cached.trim().isNotEmpty) return cached;

    final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable(fn);

    final res = await callable.call(<String, dynamic>{
      'language': language,
      'picked': picked,
      'question': <String, dynamic>{
        'id': q.id,
        'stem': q.stem,
        'answer': q.answer,
        'options': q.options,
        'topic': q.topic,
        'section': q.section,
        'language': q.language,
        'left': q.left,
        'right': q.right,
        'explanation': q.explanation,
      },
    });

    final data = res.data;
    String text;
    if (data is Map) {
      text = (data['text'] ?? data['answer'] ?? data['result'] ?? '—').toString();
    } else {
      text = (data ?? '—').toString();
    }

    text = text.trim().isEmpty ? '—' : text.trim();
    _jinnyCache[cacheKey] = text;
    return text;
  }

  Future<void> _openJinnyChat(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;

    final q = widget.questions[_i];
    final picked = widget.answers[_i] ?? '';

    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    final language = lang.startsWith('ky') ? 'ky' : 'ru';

    final cacheKey = _jinnyCacheKey(language: language, q: q, picked: picked);
    final prefilled = _jinnyCache[cacheKey];

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
            callOnce: _callJinnyOnce,
            prefilledText: (prefilled != null && prefilled.trim().isNotEmpty)
                ? prefilled
                : null,
          ),
        );
      },
    );
  }

  // -------------------- UI --------------------

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
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _ComparisonAnswerTile(letter: 'A', picked: picked, correct: q.answer, cs: cs, onTap: null)),
                    const SizedBox(width: 12),
                    Expanded(child: _ComparisonAnswerTile(letter: 'B', picked: picked, correct: q.answer, cs: cs, onTap: null)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _ComparisonAnswerTile(letter: 'C', picked: picked, correct: q.answer, cs: cs, onTap: null)),
                    const SizedBox(width: 12),
                    Expanded(child: _ComparisonAnswerTile(letter: 'D', picked: picked, correct: q.answer, cs: cs, onTap: null)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
          ] else ...[
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

          FutureBuilder<AiExplainCfg>(
            future: _loadAiExplainCfg(loc),
            builder: (context, snap) {
              final theme = Theme.of(context);
              final cs = theme.colorScheme;
              final isDark = theme.brightness == Brightness.dark;

              final cfg = snap.data;
              final enabled = (cfg?.enabled ?? true);
              final cost = (cfg?.cost ?? 0);

              final green = isDark ? const Color(0xFF2FBF71) : const Color(0xFF1E9E55);
              final costText = NumberFormat.decimalPattern(loc.localeName).format(cost);

              final q = widget.questions[_i];
              final picked = widget.answers[_i] ?? '';
              final lang = Localizations.localeOf(context).languageCode.toLowerCase();
              final language = lang.startsWith('ky') ? 'ky' : 'ru';

              final cacheKey = _jinnyCacheKey(language: language, q: q, picked: picked);
              final hasCached = _jinnyCache[cacheKey]?.trim().isNotEmpty == true;

              // Match answer-choice feel: small shadow, rounded, no "button" style
              final tileShadow = [
                BoxShadow(
                  color: cs.shadow.withOpacity(isDark ? 0.14 : 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 10),
                ),
              ];

              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: (!enabled || _aiBusy)
                    ? null
                    : () async {
                  if (hasCached) {
                    // ✅ instant reopen, no charge, no busy state
                    await _openJinnyChat(context);
                    return;
                  }

                  if (_aiBusy) return;
                  setState(() => _aiBusy = true);
                  try {
                    final gate = context.read<CurrencyGate>();

                    await _runAiExplainNoConfirm(
                      context: context,
                      gate: gate,
                      questionId: q.id,
                      language: language,
                      onAllowed: () async => _openJinnyChat(context),
                    );
                  } finally {
                    if (mounted) setState(() => _aiBusy = false);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: tileShadow,
                    border: Border.all(
                      color: cs.outline.withOpacity(isDark ? 0.28 : 0.22),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Jinny avatar (always visible)
                        Image.asset(
                          'assets/icon/quokka_large.png',
                          width: 22,
                          height: 22,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 8),

                        // Text
                        Text(
                          loc.quiz_ai_explain,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface.withOpacity(enabled ? 1.0 : 0.55),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // RIGHT SIDE: cost OR spinner
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: _aiBusy
                              ? SizedBox(
                            key: const ValueKey('spinner'),
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(green),
                            ),
                          )
                              : hasCached
                              ? Icon(
                            Icons.check_rounded,
                            key: const ValueKey('cached'),
                            size: 18,
                            color: green,
                          )
                              : Row(
                            key: const ValueKey('cost'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                costText,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: green,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.eco_rounded,
                                size: 16,
                                color: green,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openReportMistake(context),
              icon: Icon(Icons.flag_rounded, size: 18, color: cs.onSurface),
              label: Text(
                loc.report_a_mistake,
                style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface),
              ),
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
                  child: Text(
                    loc.quiz_next,
                    style: TextStyle(fontWeight: FontWeight.w900, color: cs.onPrimary),
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
}

// ───────────────────────────────────────────────────────────────
// Bottom sheet + "typing" UI
// ───────────────────────────────────────────────────────────────

class _BottomSheetSurface extends StatelessWidget {
  final Widget child;
  const _BottomSheetSurface({required this.child});

  @override
  Widget build(BuildContext context) => child;
}

class _JinnyExplainSheet extends StatefulWidget {
  final AppLocalizations loc;
  final String language;
  final Question question;
  final String picked;
  final String? prefilledText;

  final Future<String> Function({
  required String language,
  required Question q,
  required String picked,
  }) callOnce;

  const _JinnyExplainSheet({
    required this.loc,
    required this.language,
    required this.question,
    required this.picked,
    required this.callOnce,
    this.prefilledText,
  });

  @override
  State<_JinnyExplainSheet> createState() => _JinnyExplainSheetState();
}

class _JinnyExplainSheetState extends State<_JinnyExplainSheet> {
  static const double _minSize = 0.40;
  static const double _halfSize = 0.60;
  static const double _maxSize = 1.00;

  final DraggableScrollableController _sheetCtrl = DraggableScrollableController();

  bool _loading = true;

  String _fullText = '';
  List<_TwUnit> _units = const [];
  int _shownUnits = 0;
  Timer? _typeTimer;

  DateTime _lastAutoScroll = DateTime.fromMillisecondsSinceEpoch(0);
  bool _userIsScrollingList = false;

  @override
  void initState() {
    super.initState();

    final pre = widget.prefilledText;
    if (pre != null && pre.trim().isNotEmpty) {
      // ✅ Instant render (no fetch, no typing delay)
      final cleaned = _sanitize(pre);
      var formatted = _formatForReading(cleaned);

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

      _fullText = formatted;
      _units = _tokenizeToUnits(_fullText);
      _shownUnits = _units.length;
      _loading = false;
      return;
    }

    // Normal first-time flow (fetch from server)
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

    s = s.replaceAllMapped(
      RegExp(r'(^|\n)\s*(\d+)\s*[\.\)]\s+'),
          (m) => '${m.group(1)}• ${m.group(2)}. ',
    );

    s = s.replaceAllMapped(
      RegExp(r'(\b[0-9A-Za-zА-Яа-яπ]+|\))\s*\^\s*([0-9]+)\b'),
          (m) => '${m.group(1)}[[SUP:${m.group(2)}]]',
    );

    s = s.replaceAllMapped(
      RegExp(r'(?<!:)(?<!\w)(-?[0-9A-Za-zА-Яа-я]+)\s*/\s*(-?[0-9A-Za-zА-Яа-я]+)(?!\w)'),
          (m) => '[[FRAC:${m.group(1)}|${m.group(2)}]]',
    );

    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();

    s = s.replaceAllMapped(
      RegExp(r'(^|\n)(##[^\n]+)\n\s*\n+'),
          (m) => '${m.group(1)}${m.group(2)}\n',
    );

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
    setState(() => _loading = true);

    try {
      final raw = await widget.callOnce(
        language: widget.language,
        q: widget.question,
        picked: widget.picked,
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
        }
      });
    });
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
              t = _stripHeaderPrefixIncremental(
                t,
                onStripped: () => headerPrefixRemoved = true,
              );
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

    final shadow = BoxShadow(
      color: cs.shadow.withOpacity(isDark ? 0.45 : 0.16),
      blurRadius: 24,
      offset: const Offset(0, -10),
    );

    final baseStyle = TextStyle(
      height: 1.38,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: cs.onSurface,
    );

    final headerStyle = baseStyle.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w900,
      height: 1.18,
    );

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

        final spans = _buildSpans(
          visibleUnits: _visibleUnits,
          baseStyle: baseStyle,
          headerStyle: headerStyle,
          cs: cs,
        );

        return Align(
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
                                    color: cs.onSurface,
                                  ),
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
                                  spans: spans.isEmpty
                                      ? <InlineSpan>[TextSpan(text: '—', style: baseStyle)]
                                      : spans,
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
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
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

enum _TwKind { text, frac, sup }

class _TwUnit {
  final _TwKind kind;
  final String text;
  final String num;
  final String den;
  final String sup;

  const _TwUnit._({
    required this.kind,
    this.text = '',
    this.num = '',
    this.den = '',
    this.sup = '',
  });

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
