import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'currency_models.dart';

class PricingService extends ChangeNotifier {
  PricingService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  bool _ready = false;
  bool get ready => _ready;

  PricingConfig _config = PricingConfig.empty;
  PricingConfig get config => _config;

  int costOf(String actionKey) => _config.costOf(actionKey);

  void start() {
    _sub?.cancel();
    _sub = _db.doc('config/pricing').snapshots().listen((snap) {
      final data = snap.data() ?? {};

      final currencyName = (data['currencyName'] as String?)?.trim();
      final currencyCode = (data['currencyCode'] as String?)?.trim();

      final actions = (data['actions'] as Map?) ?? {};
      final Map<String, int> costs = {};

      actions.forEach((k, v) {
        if (k == null) return;
        if (v is! Map) return;

        final enabled = v['enabled'] != false;
        if (!enabled) return;

        final rawCost = v['cost'];
        final cost = (rawCost is num) ? rawCost.toInt() : 0;
        if (cost > 0) costs[k.toString()] = cost;
      });

      _config = PricingConfig(
        currencyName: currencyName?.isNotEmpty == true ? currencyName! : 'ZHALBYRAKS',
        currencyCode: currencyCode?.isNotEmpty == true ? currencyCode! : 'ZB',
        actionCosts: costs,
      );

      _ready = true;
      notifyListeners();
    }, onError: (_) {
      // keep last known config; do not crash
      _ready = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
