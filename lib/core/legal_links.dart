// Where the Privacy Policy and Terms of Use live: static pages in web/ served
// by the Banigoba web app (web/privacy.html and web/terms.html), so the same
// address works for App Store Connect, the app and a browser.
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models/shop_link.dart' show kShareHost;

final Uri kPrivacyPolicyUrl = Uri.parse('$kShareHost/privacy');
final Uri kTermsOfUseUrl = Uri.parse('$kShareHost/terms');

/// Bump when the Terms change materially; everyone is asked to agree again.
const String kTermsVersion = '2026-11-05';

/// Opens [url] in the browser; false if it could not be opened.
Future<bool> openLegalPage(Uri url) async {
  try {
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  } on Exception catch (error) {
    debugPrint('Unable to open $url: $error');
    return false;
  }
}
