import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';

import '../models/question.dart';
import '../theme/z_theme.dart';
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

class _QuizSingleReviewPageState extends State<QuizSingleReviewPage> {
  late int _i;

  // ===== AI state =====
  bool _aiSheetOpen = false;
  Future<String>? _aiFuture;
  final Map<String, String> _aiCacheByQuestionId = {};

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

    final expl = q.explanation?.trim() ?? '';

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
        title: Text(
          loc.quiz_review_question_title(_i + 1, widget.questions.length),
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===== Question card =====
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
                          color: pickedCorrect
                              ? ZTheme.greenBg
                              : ZTheme.redBg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: (pickedCorrect
                                ? ZTheme.green
                                : ZTheme.red)
                                .withOpacity(0.25),
                          ),
                        ),
                        child: Text(
                          'Q${_i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: pickedCorrect
                                ? ZTheme.green
                                : ZTheme.red,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        pickedCorrect
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: pickedCorrect
                            ? ZTheme.green
                            : ZTheme.red,
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

            // ===== Options =====
            Column(
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
                              border:
                              Border.all(color: ZTheme.border),
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

                // ===== Navigation buttons =====
                Padding(
                  padding:
                  const EdgeInsets.only(top: 2, bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _i > 0 ? _prev : null,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(16),
                            ),
                            side: BorderSide(
                              color: _i > 0
                                  ? ZTheme.purple
                                  : ZTheme.purple
                                  .withOpacity(0.25),
                            ),
                            padding:
                            const EdgeInsets.symmetric(
                                vertical: 14),
                          ),
                          child: Text(
                            loc.quiz_back,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: _i > 0
                                  ? ZTheme.purple
                                  : ZTheme.purple
                                  .withOpacity(0.35),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _i <
                              widget.questions.length - 1
                              ? _next
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ZTheme.purple,
                            disabledBackgroundColor:
                            ZTheme.purple
                                .withOpacity(0.35),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(16),
                            ),
                            padding:
                            const EdgeInsets.symmetric(
                                vertical: 14),
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
                ),
              ],
            ),

            // ===== Explanation + AI =====
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (expl.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(18),
                        border:
                        Border.all(color: ZTheme.border),
                        boxShadow: ZTheme.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.quiz_explanation,
                            style: const TextStyle(
                                fontWeight:
                                FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            expl,
                            style: const TextStyle(
                                height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // ===== AI explanation button =====
                  OutlinedButton.icon(
                    onPressed: _aiSheetOpen
                        ? null
                        : () async {
                      setState(() => _aiSheetOpen = true);

                      final lang =
                      Localizations.localeOf(context)
                          .languageCode
                          .toLowerCase();
                      final language =
                      lang.startsWith('ky')
                          ? 'ky'
                          : 'ru';

                      final cacheKey = q.id;

                      Future<String> loadAi() async {
                        final cached =
                        _aiCacheByQuestionId[
                        cacheKey];
                        if (cached != null &&
                            cached.isNotEmpty) {
                          return cached;
                        }

                        final callable =
                        FirebaseFunctions
                            .instanceFor(
                            region:
                            'europe-west1')
                            .httpsCallable(
                            'aiExplainQuestion');

                        final res = await callable.call({
                          'language': language,
                          'question': {
                            'stem': q.stem,
                            'options': q.options,
                            'answer': q.answer,
                            'picked': picked ?? '',
                          }
                        });

                        final data = res.data;
                        final text =
                        (data is Map &&
                            data['text'] !=
                                null)
                            ? data['text']
                            .toString()
                            : '—';

                        _aiCacheByQuestionId[
                        cacheKey] = text;
                        return text;
                      }

                      _aiFuture = loadAi();

                      if (!context.mounted) return;

                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.white,
                        shape:
                        const RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.vertical(
                              top:
                              Radius.circular(
                                  22)),
                        ),
                        builder: (_) {
                          return DraggableScrollableSheet(
                            expand: false,
                            initialChildSize: 0.55,
                            minChildSize: 0.35,
                            maxChildSize: 0.92,
                            builder:
                                (ctx, controller) {
                              return FutureBuilder<
                                  String>(
                                future: _aiFuture,
                                builder: (ctx, snap) {
                                  Widget body;

                                  if (snap
                                      .connectionState ==
                                      ConnectionState
                                          .waiting) {
                                    body =
                                    const Padding(
                                      padding:
                                      EdgeInsets
                                          .all(
                                          18),
                                      child: Center(
                                        child:
                                        CircularProgressIndicator(),
                                      ),
                                    );
                                  } else if (snap
                                      .hasError) {
                                    body = Padding(
                                      padding:
                                      const EdgeInsets
                                          .all(
                                          16),
                                      child: Text(
                                        'AI error: ${snap.error}',
                                        style: const TextStyle(
                                            fontWeight:
                                            FontWeight
                                                .w700),
                                      ),
                                    );
                                  } else {
                                    body = Padding(
                                      padding:
                                      const EdgeInsets
                                          .all(
                                          16),
                                      child: Text(
                                        snap.data ??
                                            '—',
                                        style:
                                        const TextStyle(
                                          height: 1.35,
                                          fontSize:
                                          14,
                                        ),
                                      ),
                                    );
                                  }

                                  return Column(
                                    children: [
                                      const SizedBox(
                                          height:
                                          10),
                                      Container(
                                        width: 44,
                                        height: 5,
                                        decoration:
                                        BoxDecoration(
                                          color: const Color(
                                              0xFFE5E7EB),
                                          borderRadius:
                                          BorderRadius.circular(
                                              999),
                                        ),
                                      ),
                                      const SizedBox(
                                          height:
                                          12),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal:
                                            16),
                                        child: Align(
                                          alignment:
                                          Alignment
                                              .centerLeft,
                                          child: Text(
                                            'AI Explanation',
                                            style: TextStyle(
                                              fontSize:
                                              15,
                                              fontWeight:
                                              FontWeight
                                                  .w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                          height:
                                          8),
                                      Expanded(
                                        child:
                                        SingleChildScrollView(
                                          controller:
                                          controller,
                                          child: body,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      );

                      if (!mounted) return;
                      setState(() {
                        _aiSheetOpen = false;
                        _aiFuture = null;
                      });
                    },
                    icon:
                    const Icon(Icons.auto_awesome_outlined),
                    label: Text(loc.quiz_ai_explain),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(16),
                      ),
                      side: BorderSide(
                          color: ZTheme.purple
                              .withOpacity(0.30)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 14),
                  const SafeArea(
                      top: false, child: SizedBox()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
