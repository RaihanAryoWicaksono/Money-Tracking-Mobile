class CurrencyFormatter {
  static String format(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final parts = absAmount.toStringAsFixed(0).split('.');
    final intPart = parts[0];
    
    String formatted = '';
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        formatted += '.';
      }
      formatted += intPart[i];
    }
    
    return '${isNegative ? '-' : ''}Rp $formatted';
  }
}