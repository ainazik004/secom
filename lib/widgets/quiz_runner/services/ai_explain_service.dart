import 'package:cloud_functions/cloud_functions.dart';
import '../models/question.dart';

class AiExplainService {
  AiExplainService._();

  static final _fn = FirebaseFunctions.instanceFor(region: 'europe-west1')
      .httpsCallable('aiExplainQuestion');

  static Future<String> explain({
    required String language, // 'ru' or 'ky'
    required Question q,
    required String picked,
  }) async {
    final res = await _fn.call({
      'language': language,
      'question': {
        'stem': q.stem,
        'options': q.options,
        'answer': q.answer,
        'picked': picked,
      },
    });

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
    final res = await _fn.call({
      'language': language,
      'userMessage': userMessage,
      'history': history,
      // Extra hint for backend (harmless if unused)
      'mode': 'chat',
      'question': {
        'stem': q.stem,
        'options': q.options,
        'answer': q.answer,
        'picked': picked,
      },
    });

    final data = res.data;
    if (data is Map && data['text'] != null) return data['text'].toString();
    return '—';
  }
}
