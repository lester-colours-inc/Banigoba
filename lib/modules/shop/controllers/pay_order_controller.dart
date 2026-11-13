// Paying a placed order online: choose how, start the try, then wait for
// the gateway (USSD approval, InnBucks code, SMS code or the card page)
// while the server is asked how it stands.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:banigoba/modules/shop/models/order_payment.dart';
import 'package:banigoba/modules/shop/services/payment_service.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class PayOrderController extends GetxController {
  PayOrderController({
    required this.orderId,
    required this.total,
    PaymentService? service,
  }) : _service = service ?? PaymentService();

  final String orderId;
  final double total;
  final PaymentService _service;

  /// How often we ask the server while the buyer approves.
  static const Duration pollEvery = Duration(seconds: 4);

  /// After this long we stop asking; the buyer can check again by hand.
  static const Duration pollFor = Duration(minutes: 3);

  final Rx<PayMethod> method = PayMethod.ecocash.obs;
  final Rxn<OrderPayment> payment = Rxn<OrderPayment>();
  final RxBool busy = false.obs;
  final RxBool waitedTooLong = false.obs;
  final TextEditingController mobile = TextEditingController();
  final TextEditingController otp = TextEditingController();

  Timer? _poll;
  DateTime? _pollStarted;

  bool get started => payment.value != null;
  bool get paid => payment.value?.status == PaymentStatus.paid;
  bool get awaitingOtp => payment.value?.status == PaymentStatus.awaitingOtp;

  void chooseMethod(PayMethod value) {
    if (started && payment.value!.status.isOpen) return;
    method.value = value;
  }

  Future<void> start() => _run(() async {
    final chosen = method.value;
    final result = await _service.start(
      orderId: orderId,
      method: chosen,
      mobile: mobile.text,
    );
    _show(result);
    final url = result.paymentUrl;
    if (chosen.hosted && url != null && result.status.isOpen) {
      final uri = Uri.tryParse(url);
      if (uri == null || uri.scheme != 'https') {
        throw const PaymentException('The card page link is not valid.');
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  });

  Future<void> confirmOtp() => _run(() async {
    final current = payment.value;
    if (current == null) return;
    _show(await _service.confirmOtp(paymentId: current.id, otp: otp.text));
  });

  Future<void> checkNow() => _run(() async {
    final current = payment.value;
    if (current == null) return;
    waitedTooLong.value = false;
    _show(await _service.refresh(current.id));
  });

  Future<void> cancelPayment() => _run(() async {
    final current = payment.value;
    if (current == null || !current.status.isOpen) return;
    _show(await _service.cancel(current.id));
  });

  /// Starts over with another try (or another method) after one failed.
  void tryAgain() {
    _stopPolling();
    payment.value = null;
    otp.clear();
  }

  Future<void> _run(Future<void> Function() task) async {
    if (busy.value) return;
    busy.value = true;
    try {
      await task();
    } on PaymentException catch (error) {
      if (!isClosed) AppToast.say(error.message);
    } finally {
      if (!isClosed) busy.value = false;
    }
  }

  void _show(OrderPayment result) {
    if (isClosed) return;
    payment.value = result;
    if (result.status == PaymentStatus.paid) {
      _stopPolling();
      AppToast.say('Payment received. Thank you!');
    } else if (result.status == PaymentStatus.pending) {
      _startPolling();
    } else {
      _stopPolling();
    }
  }

  void _startPolling() {
    if (_poll != null) return;
    _pollStarted = DateTime.now();
    waitedTooLong.value = false;
    _poll = Timer.periodic(pollEvery, (_) => _tick());
  }

  Future<void> _tick() async {
    final current = payment.value;
    if (current == null || busy.value) return;
    final started = _pollStarted ?? DateTime.now();
    if (DateTime.now().difference(started) > pollFor) {
      _stopPolling();
      waitedTooLong.value = true;
      return;
    }
    try {
      final fresh = await _service.refresh(current.id);
      if (!isClosed && payment.value?.id == fresh.id) _show(fresh);
    } on PaymentException {
      // A missed check is fine; the next tick asks again.
    }
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  @override
  void onClose() {
    _stopPolling();
    mobile.dispose();
    otp.dispose();
    super.onClose();
  }
}
