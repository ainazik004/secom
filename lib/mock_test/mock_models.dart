import 'mock_test_config.dart';

class QuestionRef {
  final String lang;     // "ru", "ky", or "neutral"
  final String section;  // "math", "reading", "grammar", "analogy", "sentence_completion"
  final String id;       // document id
  const QuestionRef({required this.lang, required this.section, required this.id});

  String key() => '$lang|$section|$id';

  Map<String, dynamic> toJson() => {'lang': lang, 'section': section, 'id': id};
  static QuestionRef fromJson(Map<String, dynamic> j) =>
      QuestionRef(lang: j['lang'], section: j['section'], id: j['id']);
}

class MockSectionState {
  final MockSectionType type;
  final int timeLimitSec;

  /// Deadline-based timing
  final DateTime? startedAt;
  final DateTime? deadlineAt;
  final DateTime? submittedAt;

  final List<QuestionRef> questions;

  const MockSectionState({
    required this.type,
    required this.timeLimitSec,
    required this.questions,
    required this.startedAt,
    required this.deadlineAt,
    required this.submittedAt,
  });

  bool get isStarted => startedAt != null && deadlineAt != null;
  bool get isSubmitted => submittedAt != null;
  bool get isLocked => isSubmitted || (deadlineAt != null && DateTime.now().isAfter(deadlineAt!));

  MockSectionState copyWith({
    DateTime? startedAt,
    DateTime? deadlineAt,
    DateTime? submittedAt,
    List<QuestionRef>? questions,
  }) {
    return MockSectionState(
      type: type,
      timeLimitSec: timeLimitSec,
      questions: questions ?? this.questions,
      startedAt: startedAt ?? this.startedAt,
      deadlineAt: deadlineAt ?? this.deadlineAt,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'timeLimitSec': timeLimitSec,
    'startedAt': startedAt?.toIso8601String(),
    'deadlineAt': deadlineAt?.toIso8601String(),
    'submittedAt': submittedAt?.toIso8601String(),
    'questions': questions.map((q) => q.toJson()).toList(),
  };

  static MockSectionState fromJson(Map<String, dynamic> j) {
    final t = MockSectionType.values.firstWhere((e) => e.name == j['type']);
    return MockSectionState(
      type: t,
      timeLimitSec: (j['timeLimitSec'] as num).toInt(),
      startedAt: j['startedAt'] == null ? null : DateTime.parse(j['startedAt']),
      deadlineAt: j['deadlineAt'] == null ? null : DateTime.parse(j['deadlineAt']),
      submittedAt: j['submittedAt'] == null ? null : DateTime.parse(j['submittedAt']),
      questions: (j['questions'] as List).map((x) => QuestionRef.fromJson(Map<String, dynamic>.from(x))).toList(),
    );
  }
}

class MockAttempt {
  final String attemptId;
  final String lang;
  final int seed;
  final int currentSectionIndex;
  final List<MockSectionState> sections;

  /// answers: questionKey -> option ("A"/"B"/...)
  final Map<String, String> answers;

  /// computed after finish (optional cache)
  final DateTime createdAt;
  final DateTime? finishedAt;

  const MockAttempt({
    required this.attemptId,
    required this.lang,
    required this.seed,
    required this.currentSectionIndex,
    required this.sections,
    required this.answers,
    required this.createdAt,
    required this.finishedAt,
  });

  bool get isFinished => finishedAt != null;

  MockAttempt copyWith({
    int? currentSectionIndex,
    List<MockSectionState>? sections,
    Map<String, String>? answers,
    DateTime? finishedAt,
  }) {
    return MockAttempt(
      attemptId: attemptId,
      lang: lang,
      seed: seed,
      currentSectionIndex: currentSectionIndex ?? this.currentSectionIndex,
      sections: sections ?? this.sections,
      answers: answers ?? this.answers,
      createdAt: createdAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'attemptId': attemptId,
    'lang': lang,
    'seed': seed,
    'currentSectionIndex': currentSectionIndex,
    'createdAt': createdAt.toIso8601String(),
    'finishedAt': finishedAt?.toIso8601String(),
    'answers': answers,
    'sections': sections.map((s) => s.toJson()).toList(),
  };

  static MockAttempt fromJson(Map<String, dynamic> j) {
    return MockAttempt(
      attemptId: j['attemptId'],
      lang: j['lang'],
      seed: (j['seed'] as num).toInt(),
      currentSectionIndex: (j['currentSectionIndex'] as num).toInt(),
      createdAt: DateTime.parse(j['createdAt']),
      finishedAt: j['finishedAt'] == null ? null : DateTime.parse(j['finishedAt']),
      answers: Map<String, String>.from(j['answers'] ?? {}),
      sections: (j['sections'] as List).map((x) => MockSectionState.fromJson(Map<String, dynamic>.from(x))).toList(),
    );
  }
}

/// Result summary per question (for overview)
class QuestionResult {
  final QuestionRef ref;
  final String? userAnswer;
  final String correctAnswer;
  final bool isCorrect;

  QuestionResult({
    required this.ref,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
  });
}
