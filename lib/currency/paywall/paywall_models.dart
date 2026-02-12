enum PaywallReason {
  notEnoughBalance,
  lockedPremium,
}

class PaywallRequest {
  final PaywallReason reason;
  final String actionKey;
  final int cost;
  final String currencyCode;
  final String? titleOverride;
  final String? messageOverride;

  const PaywallRequest({
    required this.reason,
    required this.actionKey,
    required this.cost,
    required this.currencyCode,
    this.titleOverride,
    this.messageOverride,
  });
}
