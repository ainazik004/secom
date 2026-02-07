enum MockSectionType { math, analogy, sentenceCompletion, reading, grammar }

class MockSectionSpec {
  final MockSectionType type;
  final int timeLimitSec;
  final int questionCount;
  const MockSectionSpec(this.type, this.timeLimitSec, this.questionCount);
}

/// ORT-like durations; analogy + sentence completion split.
/// Adjust counts as you wish for testing.
class MockTestConfig {
  static const List<MockSectionSpec> sections = [
    MockSectionSpec(MockSectionType.math, 90 * 60, 60),
    MockSectionSpec(MockSectionType.analogy, 15 * 60, 15),
    MockSectionSpec(MockSectionType.sentenceCompletion, 15 * 60, 15),
    MockSectionSpec(MockSectionType.reading, 60 * 60, 30),
    MockSectionSpec(MockSectionType.grammar, 35 * 60, 30),
  ];

  /// Math breakdown: comparison from neutral (10), rest from lang math (50)
  static const int mathComparisonCount = 10;
}
