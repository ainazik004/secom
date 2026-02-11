import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'currency_models.dart';

class WalletService extends ChangeNotifier {
  WalletService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  String? _activeUid;

  bool _ready = false;
  bool get ready => _ready;

  WalletState _state = WalletState.empty;
  WalletState get state => _state;

  int get balance => _state.balance;

  void start(String uid) {
    if (_activeUid == uid && _sub != null) return; // ✅ prevents resubscribe spam
    _activeUid = uid;

    _sub?.cancel();
    _ready = false;
    notifyListeners();

    _sub = _db.doc('users/$uid/wallet/main').snapshots().listen((snap) {
      final data = snap.data() ?? {};
      int asInt(dynamic v) => (v is num) ? v.toInt() : 0;

      _state = WalletState(
        balance: asInt(data['balance']),
        earnedTotal: asInt(data['earnedTotal']),
        spentTotal: asInt(data['spentTotal']),
      );

      _ready = true;
      notifyListeners();
    }, onError: (_) {
      _ready = false;
      notifyListeners();
    });
  }

  void stop() {
    _activeUid = null;
    _sub?.cancel();
    _sub = null;
    _state = WalletState.empty;
    _ready = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
