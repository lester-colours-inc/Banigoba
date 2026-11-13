import 'package:flutter_test/flutter_test.dart';

import 'package:banigoba/modules/shop/models/order_payment.dart';

void main() {
  group('OrderPayment.fromJson', () {
    test('reads the smile-pay function answer', () {
      final payment = OrderPayment.fromJson({
        'id': 'p1',
        'orderId': 'o1',
        'method': 'innbucks',
        'status': 'pending',
        'amount': 12,
        'paymentUrl': null,
        'paymentCode': '701564',
        'message': null,
      });

      expect(payment.method, PayMethod.innbucks);
      expect(payment.status, PaymentStatus.pending);
      expect(payment.amount, 12.0);
      expect(payment.paymentCode, '701564');
    });

    test('maps awaiting_otp and treats unknown statuses as pending', () {
      expect(
        PaymentStatus.fromValue('awaiting_otp'),
        PaymentStatus.awaitingOtp,
      );
      expect(PaymentStatus.fromValue('weird'), PaymentStatus.pending);
    });
  });

  test('only pending and awaiting OTP are open', () {
    expect(PaymentStatus.pending.isOpen, isTrue);
    expect(PaymentStatus.awaitingOtp.isOpen, isTrue);
    expect(PaymentStatus.paid.isOpen, isFalse);
    expect(PaymentStatus.failed.isOpen, isFalse);
  });

  test('only O\'mari and SmileCash need an OTP; only cards are hosted', () {
    expect(PayMethod.values.where((m) => m.needsOtp), [
      PayMethod.omari,
      PayMethod.smilecash,
    ]);
    expect(PayMethod.values.where((m) => m.hosted), [PayMethod.card]);
    expect(PayMethod.innbucks.needsMobile, isFalse);
  });
}
