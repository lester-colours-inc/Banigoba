// Online payment for orders. Everything goes through the smile-pay Edge
// Function, which holds the gateway keys and takes the amount from the order
// itself; the app only says which order, how, and from which number.
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

import 'package:banigoba/core/supabase/supabase_config.dart';
import 'package:banigoba/modules/shop/models/order_payment.dart';

/// A refusal or failure with words fit to show the buyer.
class PaymentException implements Exception {
  const PaymentException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PaymentService {
  static const String _function = 'smile-pay';

  Future<OrderPayment> start({
    required String orderId,
    required PayMethod method,
    String mobile = '',
  }) => _call({
    'action': 'initiate',
    'orderId': orderId,
    'method': method.value,
    if (method.needsMobile) 'mobile': mobile.trim(),
  });

  Future<OrderPayment> confirmOtp({
    required String paymentId,
    required String otp,
  }) => _call({'action': 'confirm', 'paymentId': paymentId, 'otp': otp.trim()});

  Future<OrderPayment> refresh(String paymentId) =>
      _call({'action': 'status', 'paymentId': paymentId});

  Future<OrderPayment> cancel(String paymentId) =>
      _call({'action': 'cancel', 'paymentId': paymentId});

  Future<OrderPayment> _call(Map<String, dynamic> body) async {
    try {
      final result = await supabase.functions.invoke(_function, body: body);
      return _paymentIn(result.data);
    } on FunctionException catch (error) {
      final details = error.details;
      final message = details is Map ? details['error'] : null;
      throw PaymentException(
        message is String && message.isNotEmpty
            ? message
            : 'Payment is unavailable right now. Please try again.',
      );
    }
  }

  static OrderPayment _paymentIn(Object? data) {
    final payment = data is Map ? data['payment'] : null;
    if (payment is! Map) {
      throw const PaymentException(
        'Unexpected answer from the payment service.',
      );
    }
    return OrderPayment.fromJson(Map<String, dynamic>.from(payment));
  }
}
