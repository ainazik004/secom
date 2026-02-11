import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import 'pricing_service.dart';
import 'wallet_service.dart';
import 'paywall/paywall_sheet.dart';

/// Central currency gate.
/// - Knows pricing
/// - Knows wallet state
/// - Knows Cloud Functions region
/// - Shows the paywall UI
/// - Performs authoritative spend via Cloud Functions
///
/// IMPORTANT:
/// This file does NOT disable buttons and does NOT contain UI logic
/// for specific features. It is a reusable core.
class CurrencyGate {
  CurrencyGate({
    required this.pricing,
    required this.wallet,
    this.region = 'europe-west1',
  });

  final PricingService pricing;
  final WalletService wallet;
  final String region;

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: region);

  /// Returns true if the user *currently* appears to have enough balance.
  /// This is a fast, optimistic client-side check for UX only.
  bool canAfford(String actionKey) {
    if (!pricing.ready || !wallet.ready) return true;
    final cost = pricing.costOf(actionKey);
    return wallet.balance >= cost;
  }

  /// Shows the subscription / donation paywall.
  /// Keep ALL paywall UI centralized here.
  Future<void> showPaywall(
      BuildContext context, {
        required String actionKey,
      }) async {
    final cost = pricing.costOf(actionKey);
    final currencyCode = pricing.config.currencyCode;

    await PaywallSheet.show(
      context,
      title: 'Not enough $currencyCode',
      subtitle: 'This feature costs $cost $currencyCode.',
      onSubscribe: () {
        Navigator.pop(context);
        // TODO: open subscription screen
      },
      onDonate: () {
        Navigator.pop(context);
        // TODO: open donation screen
      },
    );
  }

  /// Authoritative server-side spend.
  /// This is what actually deducts currency.
  ///
  /// Throws FirebaseFunctionsException on failure.
  Future<Map<String, dynamic>> spend({
    required String actionKey,
    required String ref,
    required String idempotencyKey,
  }) async {
    final callable = _functions.httpsCallable('spendZhalbyraks');

    final res = await callable.call({
      'actionKey': actionKey,
      'ref': ref,
      'idempotencyKey': idempotencyKey,
    });

    final data = res.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {'ok': true, 'raw': data};
  }
}
