// Verifies the commission and influencer share (K-5, K-6).
import 'package:banigoba/modules/provider/models/commission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a \$1.00 piece carries 20c commission', () {
    expect(commissionOn(1), 0.20);
  });

  test('the commission rounds to the cent', () {
    expect(commissionOn(3.33), 0.67);
    expect(commissionOn(0), 0);
  });

  test('the influencer gets 25% of the commission', () {
    expect(influencerShareOf(commissionOn(1)), 0.05);
    expect(influencerShareOf(2), 0.50);
  });

  test('rates can change', () {
    const rates = CommissionRates(commission: 0.10, influencerShare: 0.5);
    expect(commissionOn(10, rates), 1);
    expect(influencerShareOf(1, rates), 0.5);
  });
}
