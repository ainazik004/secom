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

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: (map['id'] ?? '').toString(),
      stem: (map['stem'] ?? '').toString(),
      options: (map['options'] as Map<String, dynamic>? ?? const {}),
      answer: (map['answer'] ?? '').toString(),

      // 👇 THIS is the line you care about
      explanation: (map['explanation'] is String &&
          (map['explanation'] as String).trim().isNotEmpty)
          ? (map['explanation'] as String).trim()
          : null,

      difficulty: map['difficulty']?.toString(),
      topic: map['topic']?.toString(),
      language: map['language']?.toString(),
      section: map['section']?.toString(),
    );
  }

  List<String> get optionKeys {
    final keys = options.keys.map((e) => e.toString()).toList();
    keys.sort();
    return keys;
  }
}
