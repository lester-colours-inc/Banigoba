// Paying an order online through Smile&Pay: the ways to pay and one try as
// the smile-pay Edge Function reports it.

enum PayMethod {
  ecocash('ecocash', 'EcoCash', needsMobile: true),
  onemoney('onemoney', 'OneMoney', needsMobile: true),
  innbucks('innbucks', 'InnBucks'),
  omari('omari', "O'mari", needsMobile: true, needsOtp: true),
  smilecash('smilecash', 'SmileCash', needsMobile: true, needsOtp: true),
  card('card', 'Visa / Mastercard', hosted: true);

  const PayMethod(
    this.value,
    this.label, {
    this.needsMobile = false,
    this.needsOtp = false,
    this.hosted = false,
  });

  /// What the server calls it.
  final String value;
  final String label;

  /// Asks for the wallet's mobile number.
  final bool needsMobile;

  /// Confirmed with an SMS code typed into the app.
  final bool needsOtp;

  /// Finished on the gateway's own page in the browser.
  final bool hosted;

  /// What the buyer does after starting, shown while we wait.
  String get waitingHint => switch (this) {
    PayMethod.ecocash ||
    PayMethod.onemoney => 'Check your phone and approve the $label prompt.',
    PayMethod.innbucks => 'Enter the code below in your InnBucks app.',
    PayMethod.omari ||
    PayMethod.smilecash => 'Enter the code sent to you by SMS.',
    PayMethod.card => 'Finish paying on the card page, then come back here.',
  };

  static PayMethod? fromValue(String? value) {
    for (final method in values) {
      if (method.value == value) return method;
    }
    return null;
  }
}

enum PaymentStatus {
  pending,
  awaitingOtp,
  paid,
  failed,
  cancelled;

  bool get isOpen => this == pending || this == awaitingOtp;

  static PaymentStatus fromValue(String? value) => switch (value) {
    'awaiting_otp' => awaitingOtp,
    'paid' => paid,
    'failed' => failed,
    'cancelled' => cancelled,
    _ => pending,
  };
}

class OrderPayment {
  const OrderPayment({
    required this.id,
    required this.orderId,
    required this.method,
    required this.status,
    required this.amount,
    this.paymentUrl,
    this.paymentCode,
    this.message,
  });

  /// Reads the `payment` object the smile-pay function answers with.
  factory OrderPayment.fromJson(Map<String, dynamic> json) => OrderPayment(
    id: json['id'] as String,
    orderId: json['orderId'] as String,
    method: PayMethod.fromValue(json['method'] as String?) ?? PayMethod.card,
    status: PaymentStatus.fromValue(json['status'] as String?),
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    paymentUrl: json['paymentUrl'] as String?,
    paymentCode: json['paymentCode'] as String?,
    message: json['message'] as String?,
  );

  final String id;
  final String orderId;
  final PayMethod method;
  final PaymentStatus status;
  final double amount;

  /// The card page, for [PayMethod.card].
  final String? paymentUrl;

  /// The code to enter in InnBucks.
  final String? paymentCode;

  /// The server's words for the buyer (why it failed, a wrong OTP, ...).
  final String? message;
}
