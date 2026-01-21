import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';

import '../models/question.dart';
import '../theme/z_theme.dart';
import '../widgets/round_x_button.dart';
import '../services/ai_explain_service.dart';

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
            // Question card
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: pickedCorrect ? ZTheme.greenBg : ZTheme.redBg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: (pickedCorrect ? ZTheme.green : ZTheme.red).withOpacity(0.25),
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

            // Options + nav
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
                              color: _i > 0 ? ZTheme.purple : ZTheme.purple.withOpacity(0.25),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            loc.quiz_back,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: _i > 0 ? ZTheme.purple : ZTheme.purple.withOpacity(0.35),
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

            // Explanation + Jinny
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
                    onPressed: () => _openJinnyChat(context),
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

  Future<void> _openJinnyChat(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;

    final q = widget.questions[_i];
    final picked = widget.answers[_i] ?? '';

    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    final language = lang.startsWith('ky') ? 'ky' : 'ru';

    final pickedText = picked.isEmpty ? '—' : '$picked. ${q.options[picked] ?? ''}';
    final correctText = '${q.answer}. ${q.options[q.answer] ?? ''}';
    final hiddenInitial = loc.jinny_firstPrompt(pickedText, correctText);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent, // ✅ keep outside transparent
      barrierColor: Colors.black.withOpacity(0.35),
      enableDrag: true, // allow default drag too
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
}

// ✅ IMPORTANT: keep this transparent, do NOT paint fullscreen white
class _BottomSheetSurface extends StatelessWidget {
  final Widget child;
  const _BottomSheetSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
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

  Widget _messageBubble({required String text, required bool fromJinny}) {
    final bg = fromJinny ? const Color(0xFFF3F4F6) : ZTheme.selectedFill;
    final border = fromJinny ? const Color(0xFFE5E7EB) : ZTheme.border;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
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

  Widget _chatRow({required bool isUser, required Widget bubble}) {
    const avatarSize = 34.0;
    const gap = 10.0;

    final leftAvatar = isUser ? const SizedBox(width: avatarSize, height: avatarSize) : _avatar();
    final rightAvatar = isUser ? _userAvatar() : const SizedBox(width: avatarSize, height: avatarSize);

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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      controller: _sheetCtrl,
      expand: false, // ✅ crucial: stops fullscreen white painting
      initialChildSize: _halfSize,
      minChildSize: _minSize,
      maxChildSize: _maxSize,
      builder: (ctx, sheetScrollController) {
        final listCtrl = sheetScrollController; // ✅ makes dragging work immediately

        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              child: Material(
                color: Colors.white,
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // Handle
                    Padding(
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
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
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
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    Expanded(
                      child: ListView.builder(
                        controller: listCtrl, // ✅ important
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        itemCount: _messages.length + (_sending ? 1 : 0),
                        itemBuilder: (ctx, index) {
                          if (_sending && index == _messages.length) {
                            return _chatRow(isUser: false, bubble: _typingBubble());
                          }

                          final m = _messages[index];
                          final isUser = !m.fromJinny;

                          // Start typewriter once per assistant message when it appears
                          if (!isUser && m.shown == 0 && m.fullText.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              _startTypewriterForIndex(index, listCtrl);
                            });
                          }

                          return _chatRow(
                            isUser: isUser,
                            bubble: _messageBubble(
                              text: isUser ? m.fullText : m.visibleText,
                              fromJinny: !isUser,
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
                          color: Colors.white,
                          border: Border(top: BorderSide(color: ZTheme.border)),
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
                                  color: _sending ? ZTheme.purple.withOpacity(0.35) : ZTheme.purple,
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
            ),
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
