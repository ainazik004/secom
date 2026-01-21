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
                        padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                ),
              ],
            ),

            // ===== Explanation + Jinny chat button =====
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
                          Text(expl, style: const TextStyle(height: 1.35)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  OutlinedButton(
                    onPressed: () => _openJinnyChat(context, loc, q, picked),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(color: ZTheme.purple.withOpacity(0.30)),
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

  Future<void> _openJinnyChat(
      BuildContext context,
      AppLocalizations loc,
      Question q,
      String? picked,
      ) async {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    final language = lang.startsWith('ky') ? 'ky' : 'ru';

    final pickedText = (picked == null || picked.isEmpty)
        ? '—'
        : '$picked. ${q.options[picked] ?? ''}';
    final correctText = '${q.answer}. ${q.options[q.answer] ?? ''}';
    final initialUserMessage = loc.jinny_firstPrompt(pickedText, correctText);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      enableDrag: false, // ✅ ONLY handle controls size/close
      builder: (_) {
        return _BottomSheetSurface(
          child: _JinnyChatSheet(
            loc: loc,
            language: language,
            question: q,
            picked: picked ?? '',
            initialUserMessage: initialUserMessage,
          ),
        );
      },
    );
  }
}

class _BottomSheetSurface extends StatelessWidget {
  final Widget child;
  const _BottomSheetSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: Material(
        color: Colors.white, // ✅ removes transparency
        child: child,
      ),
    );
  }
}

class _ChatMsg {
  final bool fromJinny;
  final String text;
  const _ChatMsg({required this.fromJinny, required this.text});
}

class _JinnyChatSheet extends StatefulWidget {
  final AppLocalizations loc;
  final String language; // 'ru' or 'ky'
  final Question question;
  final String picked;
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

class _JinnyChatSheetState extends State<_JinnyChatSheet>
    with WidgetsBindingObserver {
  static const double _minSize = 0.40;
  static const double _halfSize = 0.60;
  static const double _maxSize = 1.00;

  final DraggableScrollableController _sheetCtrl = DraggableScrollableController();
  double _extent = _halfSize;

  double _dismissDragPx = 0.0;
  static const double _dismissThresholdPx = 90.0;

  final List<_ChatMsg> _messages = [];
  bool _sending = false;

  final ScrollController _listCtrl = ScrollController();
  final TextEditingController _inputCtrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  bool _requestedFullOnKeyboard = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _messages.add(_ChatMsg(fromJinny: false, text: widget.initialUserMessage));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _sendToJinny(widget.initialUserMessage);
      _scrollToBottom();
    });

    _focus.addListener(() {
      if (_focus.hasFocus) {
        _requestedFullOnKeyboard = true;
        _expandToFull();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sheetCtrl.dispose();
    _listCtrl.dispose();
    _inputCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final inset = MediaQuery.of(context).viewInsets.bottom;
    if (inset > 0) {
      _requestedFullOnKeyboard = true;
      _expandToFull();
    }
  }

  Future<void> _animateToWhenAttached(double target) async {
    // ✅ fixes: "controller not attached" and ensures the expand happens
    for (int i = 0; i < 10; i++) {
      if (!mounted) return;
      if (_sheetCtrl.isAttached) {
        try {
          await _sheetCtrl.animateTo(
            target,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
          );
        } catch (_) {}
        return;
      }
      await Future.delayed(const Duration(milliseconds: 16));
    }
  }

  void _jumpToWhenAttached(double target) {
    if (!mounted) return;
    if (!_sheetCtrl.isAttached) return;
    try {
      _sheetCtrl.jumpTo(target);
    } catch (_) {}
  }

  void _expandToFull() {
    if (!mounted) return;
    if (_extent >= _maxSize) return;
    _extent = _maxSize;
    _animateToWhenAttached(_maxSize);
  }

  Future<void> _closeSheet() async {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _onHandleDragUpdate(DragUpdateDetails d) {
    final screenH = MediaQuery.of(context).size.height;
    if (screenH <= 1) return;

    final dy = d.delta.dy;
    final deltaExtent = (-dy / screenH);
    final rawNext = _extent + deltaExtent;

    if (rawNext <= _minSize) {
      _extent = _minSize;
      _jumpToWhenAttached(_minSize);

      if (dy > 0) {
        _dismissDragPx += dy;
      } else {
        _dismissDragPx = 0.0;
      }
      return;
    }

    _dismissDragPx = 0.0;
    final next = rawNext.clamp(_minSize, _maxSize);
    _extent = next;
    _jumpToWhenAttached(next);
  }

  Future<void> _onHandleDragEnd(DragEndDetails d) async {
    if (_dismissDragPx >= _dismissThresholdPx) {
      await _closeSheet();
      return;
    }

    final target = (_extent >= 0.85)
        ? _maxSize
        : (_extent <= 0.52)
        ? _minSize
        : _halfSize;

    _extent = target;
    await _animateToWhenAttached(target);
  }

  void _scrollToBottom() {
    if (!_listCtrl.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_listCtrl.hasClients) return;
      _listCtrl.animateTo(
        _listCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
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

  Widget _userAvatar() {
    return Container(
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
    );
  }

  Widget _typingBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(),
          SizedBox(width: 4),
          _Dot(delayMs: 140),
          SizedBox(width: 4),
          _Dot(delayMs: 280),
        ],
      ),
    );
  }

  Widget _messageBubble({
    required String text,
    required bool fromJinny,
  }) {
    final bg = fromJinny ? const Color(0xFFF3F4F6) : ZTheme.selectedFill;
    final border = fromJinny ? const Color(0xFFE5E7EB) : ZTheme.border;

    // ✅ bubble size = text size (like messengers), with max width
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Text(
          text,
          style: const TextStyle(
            height: 1.35,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      ),
    );
  }

  Widget _chatRow({
    required bool isUser,
    required Widget bubble,
  }) {
    const avatarSize = 34.0;
    const gap = 10.0;

    final leftAvatar =
    isUser ? const SizedBox(width: avatarSize, height: avatarSize) : _avatar();
    final rightAvatar = isUser
        ? _userAvatar()
        : const SizedBox(width: avatarSize, height: avatarSize);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(width: avatarSize, height: avatarSize, child: leftAvatar),
          const SizedBox(width: gap),

          // ✅ alignment per side, bubble fits content
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

  Future<void> _sendToJinny(String userText) async {
    if (_sending) return;
    setState(() => _sending = true);

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('aiExplainQuestion');

      final history = _messages
          .take(14)
          .map((m) => {
        'role': m.fromJinny ? 'assistant' : 'user',
        'content': m.text,
      })
          .toList();

      final res = await callable.call({
        'language': widget.language,
        'userMessage': userText,
        'history': history,
        'question': {
          'stem': widget.question.stem,
          'options': widget.question.options,
          'answer': widget.question.answer,
          'picked': widget.picked,
        }
      });

      final data = res.data;
      final text =
      (data is Map && data['text'] != null) ? data['text'].toString() : '—';

      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMsg(fromJinny: true, text: text));
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMsg(fromJinny: true, text: 'Ошибка: $e'));
        _sending = false;
      });
      _scrollToBottom();
    }
  }

  void _onSendPressed() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(_ChatMsg(fromJinny: false, text: text));
      _inputCtrl.clear();
    });

    _scrollToBottom();
    _sendToJinny(text);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    if (bottomInset > 0 && _requestedFullOnKeyboard) {
      // ensure we keep full while typing
      WidgetsBinding.instance.addPostFrameCallback((_) => _expandToFull());
    }

    return DraggableScrollableSheet(
      controller: _sheetCtrl,
      expand: false,
      initialChildSize: _halfSize,
      minChildSize: _minSize,
      maxChildSize: _maxSize,
      builder: (ctx, sheetScrollController) {
        // ✅ IMPORTANT: attach the provided controller to a dummy scroll view,
        // so the sheet stays properly "wired", but scrolling won't resize it.
        final dummy = SingleChildScrollView(
          controller: sheetScrollController,
          physics: const NeverScrollableScrollPhysics(),
          child: const SizedBox(height: 1),
        );

        return AnimatedPadding(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Stack(
            children: [
              // invisible, but keeps the draggable sheet attached
              Positioned.fill(child: dummy),

              // real UI
              Positioned.fill(
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // ✅ THE ONLY RESIZE/CLOSE HANDLE
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: _onHandleDragUpdate,
                      onVerticalDragEnd: _onHandleDragEnd,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(999),
                            ),
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
                            onPressed: _closeSheet,
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    Expanded(
                      child: ListView.builder(
                        controller: _listCtrl,
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        itemCount: _messages.length + (_sending ? 1 : 0),
                        itemBuilder: (ctx, index) {
                          if (_sending && index == _messages.length) {
                            return _chatRow(isUser: false, bubble: _typingBubble());
                          }

                          final m = _messages[index];
                          final isUser = !m.fromJinny;

                          return _chatRow(
                            isUser: isUser,
                            bubble: _messageBubble(
                              text: m.text,
                              fromJinny: !isUser,
                            ),
                          );
                        },
                      ),
                    ),

                    // ✅ SafeArea to avoid bottom overflow with keyboard/navigation bar
                    SafeArea(
                      top: false,
                      child: Container(
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

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
