import 'package:intl/intl.dart';

/// Formats money in Bangladesh Taka (BDT) for UI.
class BdtFormatter {
  BdtFormatter._();

  static final NumberFormat _fmt = NumberFormat.currency(
    locale: 'en_BD',
    symbol: '৳',
    decimalDigits: 2,
  );

  static String format(num? value) {
    if (value == null) return '৳0.00';
    return _fmt.format(value);
  }
}
