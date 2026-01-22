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

  static String? _readNonEmptyString(dynamic v) {
    if (v == null) return null;

    // Accept strings and "string-like" values safely
    final s = v.toString().trim();
    if (s.isEmpty) return null;

    // Optionally ignore "null"/"undefined" strings if your dataset has them
    if (s.toLowerCase() == 'null' || s.toLowerCase() == 'undefined') return null;

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

      // ✅ robust explanation parsing
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
