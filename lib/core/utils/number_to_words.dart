/// Convert currency numbers into Indian Numbering System words.
/// ₹500.00 -> "Five Hundred Rupees Only"
/// ₹12,500.00 -> "Twelve Thousand Five Hundred Rupees Only"
class NumberToWords {
  NumberToWords._();

  static const List<String> _units = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
    'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
    'Seventeen', 'Eighteen', 'Nineteen'
  ];

  static const List<String> _tens = [
    '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
  ];

  static String convertPaise(int paise) {
    if (paise <= 0) return 'Zero Rupees Only';

    final rupees = paise ~/ 100;
    final remainingPaise = paise % 100;

    final buffer = StringBuffer();
    if (rupees > 0) {
      buffer.write(_convertRupees(rupees));
      buffer.write(rupees == 1 ? ' Rupee' : ' Rupees');
    }

    if (remainingPaise > 0) {
      if (rupees > 0) buffer.write(' and ');
      buffer.write(_convertRupees(remainingPaise));
      buffer.write(remainingPaise == 1 ? ' Paisa' : ' Paise');
    }

    buffer.write(' Only');
    return buffer.toString();
  }

  static String _convertRupees(int n) {
    if (n < 20) return _units[n];
    if (n < 100) return '${_tens[n ~/ 10]}${n % 10 != 0 ? " ${_units[n % 10]}" : ""}';
    if (n < 1000) return '${_units[n ~/ 100]} Hundred${n % 100 != 0 ? " ${_convertRupees(n % 100)}" : ""}';
    if (n < 100000) return '${_convertRupees(n ~/ 1000)} Thousand${n % 1000 != 0 ? " ${_convertRupees(n % 1000)}" : ""}';
    if (n < 10000000) return '${_convertRupees(n ~/ 100000)} Lakh${n % 100000 != 0 ? " ${_convertRupees(n % 100000)}" : ""}';
    return '${_convertRupees(n ~/ 10000000)} Crore${n % 10000000 != 0 ? " ${_convertRupees(n % 10000000)}" : ""}';
  }
}
