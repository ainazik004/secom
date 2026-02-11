// mock_test_controller.dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../gen_l10n/app_localizations.dart';
import 'firestore_rand_sampler.dart';
import 'mock_attempt_store.dart';
import 'mock_history.dart';
import 'mock_models.dart';
import 'mock_test_config.dart';

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

  // ---------------------------------------------------------------------------
  // ✅ Pause support without changing your models:
  // We persist pause info inside attempt.answers using reserved keys.
  // ---------------------------------------------------------------------------

  static const String _kPausedFlag = '__mock_paused';
  static const String _kPausedAtMs = '__mock_paused_at_ms';

  String _kRemainingMsFor(int sectionIndex) => '__mock_remaining_ms_s$sectionIndex';

  bool get isPaused {
    final a = _attempt;
    if (a == null) return false;
    return a.answers[_kPausedFlag] == '1';
  }

  int _nowMs() => DateTime.now().millisecondsSinceEpoch;

  int _getPausedRemainingMs(MockAttempt a, int sectionIndex) {
    final raw = a.answers[_kRemainingMsFor(sectionIndex)];
    final v = int.tryParse(raw ?? '');
    return (v == null || v < 0) ? 0 : v;
  }

  String _fmt(Duration d) {
    final totalSec = d.inSeconds.clamp(0, 1 << 30);
    final mm = (totalSec ~/ 60).toString().padLeft(2, '0');
    final ss = (totalSec % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  /// Pause current section (timer stops even if user quits).
  Future<void> pause() async {
    final a = _attempt;
    if (a == null || a.isFinished) return;
    if (isPaused) return;

    final idx = a.currentSectionIndex;
    final s = a.sections[idx];

    // If section not started, start it first (so we have a stable remaining)
    if (!s.isStarted) {
      await startCurrentSectionIfNeeded();
    }

    final cur = _attempt!;
    final sec = cur.sections[cur.currentSectionIndex];

    final deadline = sec.deadlineAt;
    final remainingMs = deadline == null
        ? (sec.timeLimitSec * 1000)
        : (deadline.difference(DateTime.now()).inMilliseconds).clamp(0, 1 << 62);

    // Set deadlineAt = null to stop counting down.
    final newSections = [...cur.sections];
    newSections[idx] = sec.copyWith(deadlineAt: null);

    final newAnswers = Map<String, String>.from(cur.answers);
    newAnswers[_kPausedFlag] = '1';
    newAnswers[_kPausedAtMs] = _nowMs().toString();
    newAnswers[_kRemainingMsFor(idx)] = remainingMs.toString();

    _attempt = cur.copyWith(sections: newSections, answers: newAnswers);
    await store.save(_attempt!);
  }

  /// Resume current section (restores deadline using stored remaining).
  Future<void> resume() async {
    final a = _attempt;
    if (a == null || a.isFinished) return;
    if (!isPaused) return;

    final idx = a.currentSectionIndex;
    final s = a.sections[idx];

    final remainingMs = _getPausedRemainingMs(a, idx);

    final newDeadline = DateTime.now().add(Duration(milliseconds: remainingMs));

    final newSections = [...a.sections];
    newSections[idx] = s.copyWith(
      startedAt: s.startedAt ?? DateTime.now(),
      deadlineAt: newDeadline,
    );

    final newAnswers = Map<String, String>.from(a.answers);
    newAnswers.remove(_kPausedFlag);
    newAnswers.remove(_kPausedAtMs);
    newAnswers.remove(_kRemainingMsFor(idx));

    _attempt = a.copyWith(sections: newSections, answers: newAnswers);
    await store.save(_attempt!);
  }

  /// Call on app start / page open to restore attempt.
  Future<MockAttempt?> restore() async {
    _attempt = await store.load();
    if (_attempt != null) {
      // If paused: do NOT auto-advance by time.
      // If not paused: reconcile timing (timeouts, auto-submit, etc.)
      if (!isPaused) {
        await _reconcileTimingAndAdvance();
      }
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

      // For testing: relax exclusions if needed
      Future<List<String>> sampleIdsFrom(
          String useLang,
          String useSection,
          int count, {
            Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> q)? filter,
          }) async {
        final pivot = rng.nextDouble();
        var docs = await sampler.sample(
          col: _col(useLang, useSection),
          limit: count,
          pivot: pivot,
          excludeDocIds: recent,
          filter: filter,
        );

        // Relax exclusion if not enough
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

      states.add(
        MockSectionState(
          type: spec.type,
          timeLimitSec: spec.timeLimitSec,
          questions: refs,
          startedAt: null,
          deadlineAt: null,
          submittedAt: null,
        ),
      );
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

    final idx = a.currentSectionIndex;
    final s = a.sections[idx];

    // ✅ paused -> show stored remaining
    if (isPaused) {
      final ms = _getPausedRemainingMs(a, idx);
      return Duration(milliseconds: ms);
    }

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
    return _fmt(d);
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

    // If paused, keep it consistent: resume before submitting (optional but safer).
    if (isPaused) {
      await resume();
    }

    final cur = _attempt!;
    final idx = cur.currentSectionIndex;
    final s = cur.sections[idx];
    if (s.isSubmitted) return;

    final now = DateTime.now();
    final updated = s.copyWith(submittedAt: now);

    final newSections = [...cur.sections];
    newSections[idx] = updated;

    var nextIndex = idx + 1;

    // Advance to next not-submitted section
    while (nextIndex < newSections.length && newSections[nextIndex].isSubmitted) {
      nextIndex++;
    }

    // Finish if past last
    if (nextIndex >= newSections.length) {
      _attempt = cur.copyWith(sections: newSections, finishedAt: now);
      await store.save(_attempt!);
      await _updateHistoryAfterFinish();
      return;
    }

    _attempt = cur.copyWith(sections: newSections, currentSectionIndex: nextIndex);
    await startCurrentSectionIfNeeded();
    await store.save(_attempt!);
  }

  /// Called on restore and also can be called periodically by UI ticker.
  Future<void> tick() async {
    // If paused, do nothing (no auto-advance on time).
    if (isPaused) return;
    await _reconcileTimingAndAdvance();
  }

  Future<void> _reconcileTimingAndAdvance() async {
    final a = _attempt;
    if (a == null || a.isFinished) return;

    // If paused, do nothing.
    if (isPaused) return;

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
      _attempt = a.copyWith(
        sections: sections,
        finishedAt: DateTime.now(),
        currentSectionIndex: sections.length - 1,
      );
      await store.save(_attempt!);
      await _updateHistoryAfterFinish();
      return;
    }

    if (changed) {
      _attempt = a.copyWith(
        sections: sections,
        currentSectionIndex: idx.clamp(0, sections.length - 1),
      );
      await store.save(_attempt!);
    }
  }

  Future<void> _updateHistoryAfterFinish() async {
    final a = _attempt;
    if (a == null || !a.isFinished) return;

    final history = await MockHistory.load();
    for (final s in a.sections) {
      final sec = sectionName(s.type);
      final langUsed = a.lang;

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
