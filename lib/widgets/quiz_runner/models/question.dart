// lib/widgets/quiz_runner/models/question.dart

class Question {
  final String id;
  final String stem;

  /// For MCQ questions. Comparison questions may have empty options.
  final Map<String, dynamic> options;

  /// For comparison questions: values shown in the left/right outlined cards.
  final String? left;
  final String? right;

  /// For MCQ: A/B/C/... must exist in options.
  /// For comparison: must be A/B/C/D.
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
    this.left,
    this.right,
    this.explanation,
    this.difficulty,
    this.topic,
    this.language,
    this.section,
  });

  static String? _readNonEmptyString(dynamic v) {
    if (v == null) return null;

    final s = v.toString().trim();
    if (s.isEmpty) return null;

    if (s.toLowerCase() == 'null' || s.toLowerCase() == 'undefined') {
      return null;
    }

    return s;
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    final rawOptions = map['options'];
    final options = (rawOptions is Map)
        ? rawOptions.map((k, v) => MapEntry(k.toString(), v))
        : <String, dynamic>{};

    return Question(
      id: (map['id'] ?? '').toString(),
      stem: (map['stem'] ?? '').toString(),
      options: options,
      answer: (map['answer'] ?? '').toString(),

      // ✅ new fields for comparison
      left: _readNonEmptyString(map['left']),
      right: _readNonEmptyString(map['right']),

      explanation: _readNonEmptyString(map['explanation']),
      difficulty: _readNonEmptyString(map['difficulty']),
      topic: _readNonEmptyString(map['topic']),
      language: _readNonEmptyString(map['language']),
      section: _readNonEmptyString(map['section']),
    );
  }

  List<String> get optionKeys {
    final keys = options.keys.map((e) => e.toString()).toList();
    keys.sort();
    return keys;
  }
}
