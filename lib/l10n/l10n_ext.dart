import 'package:intl/intl.dart';
import 'package:zhalbyrak/gen_l10n/app_localizations.dart';

extension ZhalbyrakCountExt on AppLocalizations {
  /// "12 LEAVES" / "1 LEAF" (pluralization handled by l10n)
  String zhalbyrakCount(int amount) {
    final n = NumberFormat.decimalPattern(localeName).format(amount);
    return '$n ${currencyUnit(amount)}';
  }
}
