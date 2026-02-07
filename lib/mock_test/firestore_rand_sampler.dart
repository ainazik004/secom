import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class MissingIndexException implements Exception {
  final String message;
  MissingIndexException(this.message);
  @override
  String toString() => message;
}

class FirestoreRandSampler {
  final FirebaseFirestore db;
  FirestoreRandSampler(this.db);

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> sample({
    required CollectionReference<Map<String, dynamic>> col,
    required int limit,
    Set<String> excludeDocIds = const {},
    double? pivot,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> q)? filter,
  }) async {
    final p = pivot ?? Random().nextDouble();

    Query<Map<String, dynamic>> base = col.orderBy('rand');
    if (filter != null) base = filter(base);

    Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> run(Query<Map<String, dynamic>> q) async {
      try {
        final snap = await q.get();
        return snap.docs.where((d) => !excludeDocIds.contains(d.id)).toList();
      } on FirebaseException catch (e) {
        // FAILED_PRECONDITION is the "index required" error.
        if (e.code == 'failed-precondition') {
          throw MissingIndexException(
            'Firestore index required for query on ${col.path}. '
                'Open the Firebase Console link in logs to create it.',
          );
        }
        rethrow;
      }
    }

    final out = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    out.addAll(await run(base.where('rand', isGreaterThanOrEqualTo: p).limit(limit)));
    final remaining = limit - out.length;
    if (remaining > 0) {
      out.addAll(await run(base.where('rand', isLessThan: p).limit(remaining)));
    }

    out.shuffle();
    return out.take(limit).toList();
  }
}
