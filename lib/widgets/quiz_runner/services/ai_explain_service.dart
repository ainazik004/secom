// lib/widgets/quiz_runner/services/ai_explain_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import '../models/question.dart';

class AiExplainService {
  AiExplainService._();

  static final FirebaseFunctions _functions =
  FirebaseFunctions.instanceFor(region: 'europe-west1');

  static HttpsCallable _callable(String name) => _functions.httpsCallable(name);

  static String _pickEndpoint({
    required Question q,
    required bool isComparison,
  }) {
    if (isComparison) return 'aiExplainComparison';

    final sec = (q.section ?? '').toLowerCase();
    final topic = (q.topic ?? '').toLowerCase();

    // Analogy
    if (sec.contains('analogy') || topic.contains('analogy')) return 'aiExplainAnalogy';

    // Language (grammar/reading)
    if (sec.contains('reading') ||
        sec.contains('grammar') ||
        sec.contains('language') ||
        topic.contains('reading') ||
        topic.contains('grammar')) {
      return 'aiExplainLanguage';
    }

    // Default to math
    return 'aiExplainMath';
  }

  static Future<String> explain({
    required String language, // 'ru' or 'ky'
    required Question q,
    required String picked,
  }) async {
    final isComparison = _isComparison(q);
    final endpoint = _pickEndpoint(q: q, isComparison: isComparison);

    final payload = <String, dynamic>{
      'language': language,
      'question': <String, dynamic>{
        'id': q.id,
        'stem': q.stem,
        'options': q.options,
        'answer': q.answer,
        'picked': picked,
        // For comparison:
        'leftValue': q.left,
        'rightValue': q.right,
        'topic': q.topic,
        'section': q.section,
        'language': q.language,
      },
    };

    final res = await _callable(endpoint).call(payload);

    final data = res.data;
    if (data is Map && data['text'] != null) return data['text'].toString();
    return '—';
  }

  static Future<String> chat({
    required String language, // 'ru' or 'ky'
    required Question q,
    required String picked,
    required String userMessage,
    List<Map<String, String>> history = const [],
  }) async {
    // You are currently using single-shot only; keep same behavior.
    final isComparison = _isComparison(q);
    final endpoint = _pickEndpoint(q: q, isComparison: isComparison);

    final payload = <String, dynamic>{
      'language': language,
      'userMessage': userMessage,
      'history': history,
      'mode': 'chat',
      'question': <String, dynamic>{
        'id': q.id,
        'stem': q.stem,
        'options': q.options,
        'answer': q.answer,
        'picked': picked,
        'leftValue': q.left,
        'rightValue': q.right,
        'topic': q.topic,
        'section': q.section,
        'language': q.language,
      },
    };

    final res = await _callable(endpoint).call(payload);

    final data = res.data;
    if (data is Map && data['text'] != null) return data['text'].toString();
    return '—';
  }

  static bool _isComparison(Question q) {
    final t = (q.topic ?? '').toLowerCase();
    if (t == 'comparison') return true;
    if (t.startsWith('comparison/')) return true;
    if (t.contains('/comparison')) return true;
    return false;
  }
}
