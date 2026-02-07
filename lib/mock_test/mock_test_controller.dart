import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../gen_l10n/app_localizations.dart';
import 'mock_attempt_store.dart';
import 'mock_history.dart';
import 'mock_models.dart';
import 'mock_test_config.dart';
import 'firestore_rand_sampler.dart';

class MockTestController {
  final FirebaseFirestore db;
  final MockAttemptStore store;

  MockAttempt? _attempt;

  MockTestController({required this.db, required this.store});

  MockAttempt? get attempt => _attempt;

  static String sectionName(MockSectionType t) {
    return switch (t) {
      MockSectionType.math => 'math',
      MockSectionType.analogy => 'analogy',
      MockSectionType.sentenceCompletion => 'sentence_completion',
      MockSectionType.reading => 'reading',
      MockSectionType.grammar => 'grammar',
    };
  }

  CollectionReference<Map<String, dynamic>> _col(String lang, String section) =>
      db.collection('questions').doc(lang).collection(section);

  /// Call on app start / page open to restore attempt.
  Future<MockAttempt?> restore() async {
    _attempt = await store.load();
    if (_attempt != null) {
      await _reconcileTimingAndAdvance();
      await store.save(_attempt!);
    }
    return _attempt;
  }

  Future<void> startNew({required String lang}) async {
    // New unique seed each run
    final seed = DateTime.now().microsecondsSinceEpoch ^ Random().nextInt(1 << 30);
    final attemptId = 'mock_${DateTime.now().millisecondsSinceEpoch}';
    final createdAt = DateTime.now();

    final history = await MockHistory.load();
    final sampler = FirestoreRandSampler(db);

    // Prepare sections with questions (assembled once)
    final states = <MockSectionState>[];
    final rng = Random(seed);

    for (final spec in MockTestConfig.sections) {
      final sec = sectionName(spec.type);

      // Recent IDs (per bucket)
      final recent = history.getRecentIds(lang, sec);

      // For testing: we will relax exclusions if needed (no insufficient errors)
      Future<List<String>> sampleIdsFrom(String useLang, String useSection, int count,
          {Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> q)? filter}) async {
        final pivot = rng.nextDouble();
        var docs = await sampler.sample(
          col: _col(useLang, useSection),
          limit: count,
          pivot: pivot,
          excludeDocIds: recent,
          filter: filter,
        );

        // Relax exclusion if not enough (testing mode)
        if (docs.length < count) {
          docs = await sampler.sample(
            col: _col(useLang, useSection),
            limit: count,
            pivot: pivot,
            excludeDocIds: const {},
            filter: filter,
          );
        }

        return docs.map((d) => d.id).toList();
      }

      List<QuestionRef> refs;

      if (spec.type == MockSectionType.math) {
        final cmpIds = await sampleIdsFrom(
          'neutral',
          'math',
          MockTestConfig.mathComparisonCount,
          filter: (q) => q.where('topic', isEqualTo: 'comparison'),
        );

        final rest = spec.questionCount - MockTestConfig.mathComparisonCount;
        final mcqIds = await sampleIdsFrom(lang, 'math', rest);

        refs = [
          ...cmpIds.map((id) => QuestionRef(lang: 'neutral', section: 'math', id: id)),
          ...mcqIds.map((id) => QuestionRef(lang: lang, section: 'math', id: id)),
        ];
      } else {
        final ids = await sampleIdsFrom(lang, sec, spec.questionCount);
        refs = ids.map((id) => QuestionRef(lang: lang, section: sec, id: id)).toList();
      }

      states.add(MockSectionState(
        type: spec.type,
        timeLimitSec: spec.timeLimitSec,
        questions: refs,
        startedAt: null,
        deadlineAt: null,
        submittedAt: null,
      ));
    }

    _attempt = MockAttempt(
      attemptId: attemptId,
      lang: lang,
      seed: seed,
      currentSectionIndex: 0,
      sections: states,
      answers: {},
      createdAt: createdAt,
      finishedAt: null,
    );

    // Start first section immediately
    await startCurrentSectionIfNeeded();
    await store.save(_attempt!);
  }

  Future<void> startCurrentSectionIfNeeded() async {
    final a = _attempt;
    if (a == null || a.isFinished) return;

    final idx = a.currentSectionIndex;
    final s = a.sections[idx];
    if (s.isStarted) return;

    final now = DateTime.now();
    final updated = s.copyWith(
      startedAt: now,
      deadlineAt: now.add(Duration(seconds: s.timeLimitSec)),
    );

    final newSections = [...a.sections];
    newSections[idx] = updated;
    _attempt = a.copyWith(sections: newSections);
    await store.save(_attempt!);
  }

  Duration? remainingForCurrentSection() {
    final a = _attempt;
    if (a == null || a.isFinished) return null;
    final s = a.sections[a.currentSectionIndex];
    if (s.deadlineAt == null) return null;
    final d = s.deadlineAt!.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  Future<void> selectAnswer(QuestionRef ref, String option) async {
    final a = _attempt;
    if (a == null || a.isFinished) return;

    final s = a.sections[a.currentSectionIndex];
    if (s.isLocked) return;

    final key = ref.key();
    final newAnswers = Map<String, String>.from(a.answers);
    newAnswers[key] = option;
    _attempt = a.copyWith(answers: newAnswers);
    await store.save(_attempt!);
  }
  MockSectionState? get currentSection {
    final a = _attempt;
    if (a == null || a.sections.isEmpty) return null;
    final i = a.currentSectionIndex.clamp(0, a.sections.length - 1);
    return a.sections[i];
  }

  MockSectionType? get currentSectionType => currentSection?.type;

  List<QuestionRef> get currentSectionRefs => currentSection?.questions ?? const [];

  String? getPicked(QuestionRef ref) {
    final a = _attempt;
    if (a == null) return null;
    return a.answers[ref.key()];
  }

  String timeLeftLabel() {
    final d = remainingForCurrentSection();
    if (d == null) return '—';
    final totalSec = d.inSeconds.clamp(0, 1 << 30);
    final mm = (totalSec ~/ 60).toString().padLeft(2, '0');
    final ss = (totalSec % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  String sectionTitle(AppLocalizations loc, MockSectionType t) {
    switch (t) {
      case MockSectionType.math:
        return loc.math;
      case MockSectionType.analogy:
        return loc.analogy;
      case MockSectionType.sentenceCompletion:
        return loc.sentence_completion;
      case MockSectionType.reading:
        return loc.reading;
      case MockSectionType.grammar:
        return loc.grammar;
    }
  }

  Future<void> submitCurrentSection({bool dueToTimeout = false}) async {
    final a = _attempt;
    if (a == null || a.isFinished) return;

    final idx = a.currentSectionIndex;
    final s = a.sections[idx];
    if (s.isSubmitted) return;

    final now = DateTime.now();
    final updated = s.copyWith(submittedAt: now);

    final newSections = [...a.sections];
    newSections[idx] = updated;

    var nextIndex = idx + 1;

    // Advance to next not-submitted section
    while (nextIndex < newSections.length && newSections[nextIndex].isSubmitted) {
      nextIndex++;
    }

    // Finish if past last
    if (nextIndex >= newSections.length) {
      _attempt = a.copyWith(sections: newSections, finishedAt: now);
      await store.save(_attempt!);
      // Update local history after finish
      await _updateHistoryAfterFinish();
      return;
    }

    _attempt = a.copyWith(sections: newSections, currentSectionIndex: nextIndex);
    await startCurrentSectionIfNeeded();
    await store.save(_attempt!);
  }

  /// Called on restore and also can be called periodically by UI ticker.
  Future<void> tick() async {
    await _reconcileTimingAndAdvance();
  }

  Future<void> _reconcileTimingAndAdvance() async {
    final a = _attempt;
    if (a == null || a.isFinished) return;

    var idx = a.currentSectionIndex;
    var sections = [...a.sections];
    var changed = false;

    // Ensure current started
    if (!sections[idx].isStarted) {
      final now = DateTime.now();
      sections[idx] = sections[idx].copyWith(
        startedAt: now,
        deadlineAt: now.add(Duration(seconds: sections[idx].timeLimitSec)),
      );
      changed = true;
    }

    // Auto-advance through any expired sections
    while (idx < sections.length) {
      final s = sections[idx];
      final deadline = s.deadlineAt;
      final expired = deadline != null && DateTime.now().isAfter(deadline);
      if (!s.isSubmitted && expired) {
        sections[idx] = s.copyWith(submittedAt: deadline); // treat deadline as submit time
        changed = true;
        idx++;
        if (idx < sections.length && !sections[idx].isStarted) {
          final now = DateTime.now();
          sections[idx] = sections[idx].copyWith(
            startedAt: now,
            deadlineAt: now.add(Duration(seconds: sections[idx].timeLimitSec)),
          );
          changed = true;
        }
        continue;
      }
      break;
    }

    // Finished?
    if (sections.every((s) => s.isSubmitted)) {
      _attempt = a.copyWith(sections: sections, finishedAt: DateTime.now(), currentSectionIndex: sections.length - 1);
      await store.save(_attempt!);
      await _updateHistoryAfterFinish();
      return;
    }

    if (changed) {
      _attempt = a.copyWith(sections: sections, currentSectionIndex: idx.clamp(0, sections.length - 1));
      await store.save(_attempt!);
    }
  }

  Future<void> _updateHistoryAfterFinish() async {
    final a = _attempt;
    if (a == null || !a.isFinished) return;

    final history = await MockHistory.load();
    for (final s in a.sections) {
      final sec = sectionName(s.type);
      // Save only doc ids per bucket (lang/section)
      final langUsed = a.lang;

      // Neutral math is separate bucket
      if (s.type == MockSectionType.math) {
        final neutralIds = s.questions.where((q) => q.lang == 'neutral').map((q) => q.id).toList();
        final langMathIds = s.questions.where((q) => q.lang == langUsed).map((q) => q.id).toList();
        history.addUsedIds('neutral', 'math', neutralIds);
        history.addUsedIds(langUsed, 'math', langMathIds);
      } else {
        final ids = s.questions.map((q) => q.id).toList();
        history.addUsedIds(langUsed, sec, ids);
      }
    }
    await history.save();
  }

  Future<void> clearAttempt() async {
    _attempt = null;
    await store.clear();
  }

}
