// lib/mock_test/mock_question_loader.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mock_models.dart';

class MockQuestion {
  final QuestionRef ref;
  final Map<String, dynamic> raw;

  MockQuestion(this.ref, this.raw);

  // ---------------------------
  // ✅ Compatibility getters (match your normal Question model fields)
  // ---------------------------
  String get id => ref.id;
  String get section => ref.section;
  String get language => ref.lang;

  // Your JSON uses "answer"
  String get answer => (raw['answer'] ?? '').toString();

  // Keep old name too (some code uses .correct)
  String get correct => answer;

  String get topic => (raw['topic'] ?? '').toString();
  String get stem => (raw['stem'] ?? '').toString();
  String? get explanation => raw['explanation']?.toString();

  // Comparison detection
  bool get isComparison {
    final t = topic.toLowerCase();
    return t == 'comparison' ||
        t.startsWith('comparison/') ||
        t.contains('/comparison') ||
        (raw.containsKey('left') && raw.containsKey('right'));
  }

  // MCQ options map
  Map<String, String> get options {
    final o = raw['options'];
    if (o is Map) {
      final m = Map<String, dynamic>.from(o);
      return m.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return {};
  }

  // Common helper used by UI / single review page
  List<String> get optionKeys {
    final keys = options.keys.toList();
    keys.sort(); // A,B,C,D
    return keys;
  }

  // Comparison fields
  String get left => (raw['left'] ?? '').toString();
  String get right => (raw['right'] ?? '').toString();
}

class MockQuestionLoader {
  final FirebaseFirestore db;
  MockQuestionLoader(this.db);

  Future<MockQuestion> loadOne(QuestionRef ref) async {
    final doc = await db
        .collection('questions')
        .doc(ref.lang)
        .collection(ref.section)
        .doc(ref.id)
        .get();

    final data = doc.data();
    if (data == null) {
      // Avoid crash, but keep required fields present
      return MockQuestion(ref, {
        'stem': 'Missing question: ${ref.key()}',
        'answer': '',
        'options': <String, String>{},
        'topic': '',
      });
    }

    return MockQuestion(ref, data);
  }
}
