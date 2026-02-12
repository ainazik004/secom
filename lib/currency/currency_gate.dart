import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'paid_confirm_dialog.dart';
import 'paywall/paywall_sheet.dart';
import 'paid_confirm_dialog.dart';
import 'pricing_service.dart';
import 'wallet_service.dart';
import 'paywall/paywall_models.dart';

class CurrencyGate {
  CurrencyGate({
    required this.pricing,
    required this.wallet,
    this.region = 'europe-west1',
  });

  final PricingService pricing;
  final WalletService wallet;
  final String region;

  FirebaseFunctions get _functions => FirebaseFunctions.instanceFor(region: region);

  int costOf(String actionKey) => pricing.costOf(actionKey);

  bool canAffordNow(String actionKey) {
    // If data not loaded yet, do not block UX; let server enforce.
    if (!pricing.ready || !wallet.ready) return true;
    final cost = pricing.costOf(actionKey);
    return wallet.balance >= cost;
  }

  Future<void> showNotEnoughPaywall(
      BuildContext context, {
        required String actionKey,
        String? title,
        String? message,
      }) async {
    final cost = pricing.costOf(actionKey);
    final code = pricing.config.currencyCode;

    await PaywallSheet.show(
      context,
      request: PaywallRequest(
        reason: PaywallReason.notEnoughBalance,
        actionKey: actionKey,
        cost: cost,
        currencyCode: code,
        titleOverride: title,
        messageOverride: message,
      ),
      onSubscribe: () {
        Navigator.pop(context);
        // TODO: open subscription screen/page
      },
      onDonate: () {
        Navigator.pop(context);
        // TODO: open donation / purchase currency screen/page
      },
    );
  }

  Future<Map<String, dynamic>> spend({
    required String actionKey,
    required String ref,
    required String idempotencyKey,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseFunctionsException(code: 'unauthenticated', message: 'NO_USER');
    }

    Future<Map<String, dynamic>> _call() async {
      final callable = _functions.httpsCallable(
        'spendZhalbyraks',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 12),
        ),
      );

      final res = await callable.call({
        'actionKey': actionKey,
        'ref': ref,
        'idempotencyKey': idempotencyKey,
      });

      final data = res.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {'ok': true, 'raw': data};
    }

    try {
      // ✅ normal token (fast)
      await user.getIdToken();
      return await _call();
    } on FirebaseFunctionsException catch (e) {
      // ✅ if token was stale, refresh once and retry
      if (e.code == 'unauthenticated') {
        await user.getIdToken(true);
        return await _call();
      }
      rethrow;
    }
  }

  /// This is the reusable pattern you will apply to onPressed later.
  /// - Buttons remain enabled
  /// - Fast local check -> show paywall immediately
  /// - Server spend remains authoritative (prevents bypass)
  Future<T?> guardAndSpend<T>({
    required BuildContext context,
    required String actionKey,
    required String ref,
    required String idempotencyKey,
    required Future<T> Function() onAllowed,
  }) async {
    final cost = pricing.costOf(actionKey);

    // 🔒 Show confirmation BEFORE spending
    final confirmed = await PaidConfirmDialog.show(
      context,
      cost: cost,
    );

    if (!confirmed) return null;

    try {
      await spend(
        actionKey: actionKey,
        ref: ref,
        idempotencyKey: idempotencyKey,
      );

      return await onAllowed();
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition' &&
          e.message == 'NOT_ENOUGH_ZHALBYRAKS') {
        await showNotEnoughPaywall(context, actionKey: actionKey);
        return null;
      }
      rethrow;
    }
  }

  Future<void> refund({
    required String actionKey,
    required String idempotencyKey,
    String? reason,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await user.getIdToken(true);

    final callable = _functions.httpsCallable('refundZhalbyraks');

    await callable.call({
      'actionKey': actionKey,
      'idempotencyKey': idempotencyKey,
      'reason': reason ?? 'ACTION_FAILED',
    });
  }

}
