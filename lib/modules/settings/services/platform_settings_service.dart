// Reads the platform's commission rates (see models/commission.dart), which
// curators can change. Falls back to the defaults when they cannot be read, so
// checkout never blocks on it; the database uses its own stored rates when the
// order is placed.
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:banigoba/core/supabase/supabase_config.dart';
import 'package:banigoba/modules/provider/models/commission.dart';

class PlatformSettingsService {
  Future<CommissionRates> rates() async {
    try {
      final row = await supabase
          .from('platform_settings')
          .select('commission_rate, influencer_share')
          .maybeSingle();
      if (row == null) return const CommissionRates();
      return CommissionRates(
        commission: (row['commission_rate'] as num).toDouble(),
        influencerShare: (row['influencer_share'] as num).toDouble(),
      );
    } on PostgrestException {
      return const CommissionRates();
    }
  }
}
