// The "Collection details" / "Delivery address" dialog's fields and checks.
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class CollectionAddressController extends GetxController {
  CollectionAddressController({this.deliveryOnly = false});

  final bool deliveryOnly;

  final street = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  final postal = TextEditingController();
  final country = TextEditingController();
  final pickup = TextEditingController();
  final RxBool usePickupPoint = false.obs;

  @override
  void onClose() {
    street.dispose();
    city.dispose();
    state.dispose();
    postal.dispose();
    country.dispose();
    pickup.dispose();
    super.onClose();
  }

  void setUsePickupPoint(bool value) => usePickupPoint.value = value;

  /// The address to save, or null while required fields are empty.
  Map<String, dynamic>? result() {
    final streetText = street.text.trim();
    final cityText = city.text.trim();
    final countryText = country.text.trim();
    if (usePickupPoint.value) {
      final pickupPoint = pickup.text.trim();
      if (pickupPoint.isEmpty ||
          streetText.isEmpty ||
          cityText.isEmpty ||
          countryText.isEmpty) {
        return null;
      }
      return {
        'collectionPreference': 'collection_point',
        'pickupPoint': pickupPoint,
        'street': streetText,
        'city': cityText,
        'state': state.text.trim(),
        'postalCode': postal.text.trim(),
        'country': countryText,
      };
    }
    if (streetText.isEmpty || cityText.isEmpty || countryText.isEmpty) {
      return null;
    }
    return {
      'collectionPreference': 'address',
      'street': streetText,
      'city': cityText,
      'state': state.text.trim(),
      'postalCode': postal.text.trim(),
      'country': countryText,
    };
  }
}
