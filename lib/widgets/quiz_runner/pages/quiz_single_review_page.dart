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
                  );
                }),

                // ===== Navigation buttons =====
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 10),
                  child: Row(
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
                          onPressed:
                          _i < widget.questions.length - 1 ? _next : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ZTheme.purple,
                            disabledBackgroundColor:
                            ZTheme.purple.withOpacity(0.35),
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
                ),
              ],
            ),

            // ===== Explanation + Jinny chat =====
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (expl.isNotEmpty) ...[
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
                            expl,
                            style: const TextStyle(height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  OutlinedButton(
                    onPressed: () => _openJinnyChat(
                      loc: loc,
                      q: q,
                      picked: picked,
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(color: ZTheme.purple.withOpacity(0.30)),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 14,
                      ),
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
                          // feel like “Jinny explains”
                          loc.quiz_ai_explain,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),
                  const SafeArea(top: false, child: SizedBox()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openJinnyChat({
    required AppLocalizations loc,
    required Question q,
    required String? picked,
  }) async {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    final language = lang.startsWith('ky') ? 'ky' : 'ru';

    // Initial user prompt (explicit, better than just “Explain”)
    final initialUserMessage = _buildInitialUserPrompt(
      loc: loc,
      q: q,
      picked: picked,
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return _JinnyChatSheet(
          loc: loc,
          language: language,
          question: q,
          picked: picked,
          initialUserMessage: initialUserMessage,
        );
      },
    );
  }

  String _buildInitialUserPrompt({
    required AppLocalizations loc,
    required Question q,
    required String? picked,
  }) {
    final pickedText = (picked == null || picked.isEmpty)
        ? '—'
        : '${picked}. ${q.options[picked] ?? ''}';

    final correctText = '${q.answer}. ${q.options[q.answer] ?? ''}';

    // Keep it short but informative.
    // You can localize later; for now this works in both RU/KY because Jinny responds in `language`.
    return 'Explain this question step-by-step. '
        'My answer: $pickedText. '
        'Correct answer: $correctText. '
        'Also explain why the other options are wrong.';
  }
}

class _ChatMsg {
  final bool fromJinny;
  final String text;
  final DateTime ts;
  const _ChatMsg({
    required this.fromJinny,
    required this.text,
    required this.ts,
  });
}

class _JinnyChatSheet extends StatefulWidget {
  final AppLocalizations loc;
  final String language; // 'ru' or 'ky'
  final Question question;
  final String? picked;
  final String initialUserMessage;

  const _JinnyChatSheet({
    required this.loc,
    required this.language,
    required this.question,
    required this.picked,
    required this.initialUserMessage,
  });

  @override
  State<_JinnyChatSheet> createState() => _JinnyChatSheetState();
}

class _JinnyChatSheetState extends State<_JinnyChatSheet> {
  final _inputCtrl = TextEditingController();
  final _focus = FocusNode();

  // reverse: true list => controller at 0.0 is bottom (latest)
  final _scrollCtrl = ScrollController();

  final List<_ChatMsg> _messages = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();

    // Seed conversation with an initial user message and auto-answer.
    _messages.add(_ChatMsg(
      fromJinny: false,
      text: widget.initialUserMessage,
      ts: DateTime.now(),
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendToJinny(widget.initialUserMessage, isInitial: true);
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _focus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    // reverse: true => bottom is offset 0
    _scrollCtrl.animateTo(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
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

  Widget _bubble({
    required String text,
    required bool fromJinny,
    bool isTyping = false,
  }) {
    final bg = fromJinny ? const Color(0xFFF3F4F6) : ZTheme.selectedFill;
    final border = fromJinny ? const Color(0xFFE5E7EB) : ZTheme.border;
    final align = fromJinny ? CrossAxisAlignment.start : CrossAxisAlignment.end;

    Widget content;
    if (isTyping) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _Dot(),
          SizedBox(width: 4),
          _Dot(delayMs: 140),
          SizedBox(width: 4),
          _Dot(delayMs: 280),
        ],
      );
    } else {
      content = Text(
        text,
        style: const TextStyle(
          height: 1.35,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
        ),
      );
    }

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: content,
        ),
      ],
    );
  }

  Widget _chatRow({
    required Widget leading,
    required Widget bubble,
    required bool alignRight,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
        alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: alignRight
            ? [
          Flexible(child: bubble),
          const SizedBox(width: 10),
          leading,
        ]
            : [
          leading,
          const SizedBox(width: 10),
          Flexible(child: bubble),
        ],
      ),
    );
  }

  Future<void> _sendToJinny(String userText, {bool isInitial = false}) async {
    if (_sending) return;
    setState(() => _sending = true);

    // Show typing bubble immediately
    setState(() {});
    _scrollToBottom();

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('aiExplainQuestion');

      // We send: question context + picked + user's message + short chat history
      final history = _messages
          .take(14)
          .map((m) => {
        'role': m.fromJinny ? 'assistant' : 'user',
        'content': m.text,
      })
          .toList();

      final res = await callable.call({
        'language': widget.language,
        'userMessage': userText, // ✅ new: enables real “chat”
        'history': history, // ✅ new: keeps context between turns
        'question': {
          'stem': widget.question.stem,
          'options': widget.question.options,
          'answer': widget.question.answer,
          'picked': widget.picked ?? '',
        }
      });

      final data = res.data;
      final text = (data is Map && data['text'] != null)
          ? data['text'].toString()
          : '—';

      if (!mounted) return;

      setState(() {
        _messages.add(_ChatMsg(fromJinny: true, text: text, ts: DateTime.now()));
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMsg(
          fromJinny: true,
          text: 'Ошибка: $e',
          ts: DateTime.now(),
        ));
        _sending = false;
      });
      _scrollToBottom();
    }
  }

  void _onSendPressed() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(_ChatMsg(fromJinny: false, text: text, ts: DateTime.now()));
      _inputCtrl.clear();
    });

    _scrollToBottom();
    _sendToJinny(text);
  }

  @override
  Widget build(BuildContext context) {
    // To make typing comfortable and the sheet "go to top",
    // we combine DraggableScrollableSheet + AnimatedPadding(viewInsets).
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.70,
      minChildSize: 0.40,
      maxChildSize: 0.98, // ✅ roll almost full screen
      builder: (ctx, dragCtrl) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

        return AnimatedPadding(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 10),

              // Header
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
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            _sending ? 'typing…' : 'online',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Chat list (reverse => newest near bottom, easier to keep input visible)
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true,
                  padding: const EdgeInsets.only(top: 8, bottom: 12),
                  itemCount: _messages.length + (_sending ? 1 : 0),
                  itemBuilder: (ctx, index) {
                    // index 0 is "latest" because reverse: true
                    if (_sending && index == 0) {
                      return _chatRow(
                        leading: _avatar(),
                        bubble: _bubble(
                          text: '',
                          fromJinny: true,
                          isTyping: true,
                        ),
                        alignRight: false,
                      );
                    }

                    final msgIndex = _sending ? index - 1 : index;
                    final m = _messages[_messages.length - 1 - msgIndex];

                    final isUser = !m.fromJinny;
                    return _chatRow(
                      alignRight: isUser,
                      leading: isUser
                          ? Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: ZTheme.pillBg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: ZTheme.border),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.person_rounded,
                          size: 18,
                          color: Color(0xFF6B7280),
                        ),
                      )
                          : _avatar(),
                      bubble: _bubble(
                        text: m.text,
                        fromJinny: !isUser,
                      ),
                    );
                  },
                ),
              ),

              // Input bar
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: ZTheme.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        focusNode: _focus,
                        textInputAction: TextInputAction.send,
                        minLines: 1,
                        maxLines: 4,
                        onSubmitted: (_) => _onSendPressed(),
                        decoration: InputDecoration(
                          hintText: widget.loc.quiz_ai_explain,
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
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
                      onTap: _sending ? null : _onSendPressed,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _sending
                              ? ZTheme.purple.withOpacity(0.35)
                              : ZTheme.purple,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // This makes the drag controller used (so you can drag scroll all the way)
              // by connecting to something; no visible UI impact.
              SizedBox(height: 0, child: SingleChildScrollView(controller: dragCtrl)),
            ],
          ),
        );
      },
    );
  }
}

// Animated typing dots
class _Dot extends StatefulWidget {
  final int delayMs;
  const _Dot({this.delayMs = 0});

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
          color: const Color(0xFF9CA3AF),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
