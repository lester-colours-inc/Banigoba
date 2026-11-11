// The platform's commission and the influencer's share of it (review items
// K-5, K-6).
//
// Decided 22 Oct 2026: the commission is a percentage added on top of the
// seller's price. A $1.00 piece costs the buyer $1.20 and the seller keeps the
// full $1.00. The influencer whose post or link brought the sale gets a share
// of the commission (25%: 5c on a $1.00 piece). The database works the same
// numbers out when the order is placed; the app only shows them.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'commission.freezed.dart';

/// Defaults, used until the real rates are read from the platform settings.
const double kDefaultCommissionRate = 0.20;
const double kDefaultInfluencerShare = 0.25;

@freezed
abstract class CommissionRates with _$CommissionRates {
  const CommissionRates._();

  const factory CommissionRates({
    /// Fraction of the seller's price added for the platform.
    @Default(kDefaultCommissionRate) double commission,

    /// Fraction of the commission paid to the referring influencer.
    @Default(kDefaultInfluencerShare) double influencerShare,
  }) = _CommissionRates;
}

double _roundToCents(double value) => (value * 100).roundToDouble() / 100;

/// The commission on [itemsTotal], to the cent.
double commissionOn(
  double itemsTotal, [
  CommissionRates rates = const CommissionRates(),
]) => _roundToCents(itemsTotal * rates.commission);

/// The influencer's part of [commission], to the cent.
double influencerShareOf(
  double commission, [
  CommissionRates rates = const CommissionRates(),
]) => _roundToCents(commission * rates.influencerShare);
