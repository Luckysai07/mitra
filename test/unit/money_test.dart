import 'package:flutter_test/flutter_test.dart';
import 'package:mitra/core/utils/money.dart';

void main() {
  group('Money Unit Tests', () {
    test('Zero Money initialization', () {
      const money = Money.zero;
      expect(money.paise, equals(0));
      expect(money.rupees, equals(0.0));
      expect(money.isZero, isTrue);
      expect(money.isPositive, isFalse);
      expect(money.isNegative, isFalse);
    });

    test('Money from rupees factory constructor', () {
      final m1 = Money.fromRupees(100.50);
      expect(m1.paise, equals(10050));
      expect(m1.rupees, equals(100.50));

      final m2 = Money.fromRupees(5000);
      expect(m2.paise, equals(500000));
    });

    test('Integer arithmetic addition and subtraction (zero float drift)', () {
      const income = Money(500000); // ₹5,000.00
      const expense = Money(150075); // ₹1,500.75

      final balance = income - expense;
      expect(balance.paise, equals(349925)); // ₹3,499.25
      expect(balance.rupees, equals(3499.25));

      final doubleIncome = income + income;
      expect(doubleIncome.paise, equals(1000000)); // ₹10,000.00
    });

    test('Money formatting methods', () {
      const amount = Money(12345678); // ₹1,23,456.78
      expect(amount.formatted, equals('₹1,23,456.78'));

      const lacAmount = Money(12000000); // ₹1,20,000.00
      expect(lacAmount.compact, equals('₹1.2L'));

      const thousandAmount = Money(5000000); // ₹50,000.00
      expect(thousandAmount.compact, equals('₹50.0K'));

      const positive = Money(500000);
      expect(positive.signedFormatted, equals('+₹5,000.00'));

      const negative = Money(-150000);
      expect(negative.signedFormatted, equals('−₹1,500.00'));
    });

    test('Money comparison operators', () {
      const m1 = Money(5000);
      const m2 = Money(10000);

      expect(m1 < m2, isTrue);
      expect(m2 > m1, isTrue);
      expect(m1 <= m2, isTrue);
      expect(m1 == const Money(5000), isTrue);
    });
  });
}
