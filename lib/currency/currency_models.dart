class PricingConfig {
  final String currencyName;
  final String currencyCode;
  final Map<String, int> actionCosts; // actionKey -> cost

  const PricingConfig({
    required this.currencyName,
    required this.currencyCode,
    required this.actionCosts,
  });

  int costOf(String actionKey) => actionCosts[actionKey] ?? 0;

  static const empty = PricingConfig(
    currencyName: 'ZHALBYRAKS',
    currencyCode: 'ZB',
    actionCosts: {},
  );
}

class WalletState {
  final int balance;
  final int earnedTotal;
  final int spentTotal;

  const WalletState({
    required this.balance,
    required this.earnedTotal,
    required this.spentTotal,
  });

  static const empty = WalletState(balance: 0, earnedTotal: 0, spentTotal: 0);
}
