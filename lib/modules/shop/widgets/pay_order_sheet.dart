// The bottom sheet that pays a placed order online through Smile&Pay.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/shop/controllers/pay_order_controller.dart';
import 'package:banigoba/modules/shop/models/order_payment.dart';

Future<void> showPayOrderSheet(
  BuildContext context, {
  required String orderId,
  required double total,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => GetBuilder<PayOrderController>(
      init: PayOrderController(orderId: orderId, total: total),
      global: false,
      builder: (controller) => _PayOrderSheet(controller: controller),
    ),
  );
}

class _PayOrderSheet extends StatelessWidget {
  const _PayOrderSheet({required this.controller});

  final PayOrderController controller;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + inset),
        child: Obx(() {
          final payment = controller.payment.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pay \$${controller.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (payment == null)
                _ChooseMethod(controller: controller)
              else
                _Progress(controller: controller, payment: payment),
            ],
          );
        }),
      ),
    );
  }
}

class _ChooseMethod extends StatelessWidget {
  const _ChooseMethod({required this.controller});

  final PayOrderController controller;

  @override
  Widget build(BuildContext context) {
    final chosen = controller.method.value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final method in PayMethod.values)
              ChoiceChip(
                key: ValueKey('pay_${method.value}'),
                label: Text(method.label),
                selected: chosen == method,
                onSelected: (_) => controller.chooseMethod(method),
              ),
          ],
        ),
        if (chosen.needsMobile) ...[
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('pay_mobile'),
            controller: controller.mobile,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: InputDecoration(
              labelText: '${chosen.label} number',
              hintText: '0771234567',
              border: const OutlineInputBorder(),
            ),
          ),
        ],
        if (chosen.hosted)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'You will enter your card on ZB Bank\'s secure Smile&Pay page.',
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('pay_start'),
          onPressed: controller.busy.value ? null : controller.start,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: Text(
            controller.busy.value ? 'Starting...' : 'Pay with ${chosen.label}',
          ),
        ),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.controller, required this.payment});

  final PayOrderController controller;
  final OrderPayment payment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final busy = controller.busy.value;
    final message = payment.message;

    final children = <Widget>[
      switch (payment.status) {
        PaymentStatus.paid => _StatusLine(
          icon: Icons.check_circle,
          color: colors.primary,
          text: 'Paid with ${payment.method.label}. The shop has been told.',
        ),
        PaymentStatus.failed || PaymentStatus.cancelled => _StatusLine(
          icon: Icons.error_outline,
          color: colors.error,
          text: message ?? 'The payment did not go through.',
        ),
        PaymentStatus.pending || PaymentStatus.awaitingOtp => _StatusLine(
          icon: Icons.hourglass_top,
          color: colors.onSurfaceVariant,
          text: payment.method.waitingHint,
        ),
      },
    ];

    final code = payment.paymentCode;
    if (code != null && payment.status.isOpen) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SelectableText(
            code,
            key: const ValueKey('pay_code'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
        ),
      );
    }

    if (payment.status == PaymentStatus.awaitingOtp) {
      if (message != null) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(message, style: TextStyle(color: colors.error)),
          ),
        );
      }
      children.addAll([
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('pay_otp'),
          controller: controller.otp,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 8,
          decoration: const InputDecoration(
            labelText: 'Code from SMS',
            border: OutlineInputBorder(),
          ),
        ),
        FilledButton(
          key: const ValueKey('pay_confirm_otp'),
          onPressed: busy ? null : controller.confirmOtp,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: Text(busy ? 'Confirming...' : 'Confirm payment'),
        ),
      ]);
    }

    if (payment.status == PaymentStatus.pending) {
      children.addAll([
        const SizedBox(height: 12),
        if (controller.waitedTooLong.value)
          const Text('Still waiting. Approve the payment, then check again.')
        else
          const LinearProgressIndicator(),
        const SizedBox(height: 12),
        OutlinedButton(
          key: const ValueKey('pay_check'),
          onPressed: busy ? null : controller.checkNow,
          child: const Text('I have paid, check again'),
        ),
      ]);
    }

    if (payment.status.isOpen) {
      children.add(
        TextButton(
          key: const ValueKey('pay_cancel'),
          onPressed: busy ? null : controller.cancelPayment,
          child: const Text('Cancel payment'),
        ),
      );
    } else if (payment.status == PaymentStatus.paid) {
      children.addAll([
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('pay_done'),
          onPressed: Get.back<void>,
          child: const Text('Done'),
        ),
      ]);
    } else {
      children.addAll([
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('pay_retry'),
          onPressed: controller.tryAgain,
          child: const Text('Try again'),
        ),
        TextButton(
          onPressed: Get.back<void>,
          child: const Text('Pay at the shop instead'),
        ),
      ]);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}
