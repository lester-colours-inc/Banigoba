import 'package:banigoba/modules/provider/models/provider_roles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('providerRolesOf', () {
    test('is empty for an ordinary customer', () {
      expect(providerRolesOf({'displayName': 'Tendai'}), isEmpty);
    });

    test('reads the stored roles', () {
      final roles = providerRolesOf({
        'providerRoles': ['designer', 'salon'],
      });

      expect(roles, [ProviderRole.designer, ProviderRole.salon]);
    });

    test('ignores unknown stored roles', () {
      expect(
        providerRolesOf({
          'providerRoles': ['shop', 'wizard'],
        }),
        [ProviderRole.shop],
      );
    });

    test('carries over shops, designers and salons set up before', () {
      final roles = providerRolesOf({
        'isSeller': true,
        'designerProfile': {'active': true},
        'agentProfile': {'active': true, 'type': 'hair'},
      });

      expect(roles, [
        ProviderRole.shop,
        ProviderRole.designer,
        ProviderRole.salon,
      ]);
    });

    test('does not count an inactive profile or a clothes agent', () {
      final roles = providerRolesOf({
        'designerProfile': {'active': false},
        'agentProfile': {'active': true, 'type': 'clothes'},
      });

      expect(roles, isEmpty);
    });

    test('lists each role once, in a fixed order', () {
      final roles = providerRolesOf({
        'providerRoles': ['salon', 'shop', 'shop'],
        'isSeller': true,
      });

      expect(roles, [ProviderRole.shop, ProviderRole.salon]);
    });
  });

  group('isProviderMode', () {
    test('is on when the user last used the provider side', () {
      expect(
        isProviderMode({
          'providerRoles': ['shop'],
          'providerMode': true,
        }),
        isTrue,
      );
    });

    test('is off when switched back to customer', () {
      expect(
        isProviderMode({
          'providerRoles': ['shop'],
          'providerMode': false,
          'sellerMode': true,
        }),
        isFalse,
      );
    });

    test('follows the old Seller Mode switch until the user switches', () {
      expect(isProviderMode({'isSeller': true, 'sellerMode': true}), isTrue);
    });

    test('is never on without a provider role', () {
      expect(isProviderMode({'providerMode': true}), isFalse);
    });
  });

  group('providerProfileUpdate', () {
    test('creates a profile section for each chosen role', () {
      final update = providerProfileUpdate(
        roles: [ProviderRole.shop, ProviderRole.designer, ProviderRole.salon],
        businessName: ' Glow Boutique ',
        location: 'Harare',
      );

      expect(update['providerRoles'], ['shop', 'designer', 'salon']);
      expect(update['isSeller'], isTrue);
      expect((update['shop'] as Map)['name'], 'Glow Boutique');
      expect(update['isDesigner'], isTrue);
      expect((update['designerProfile'] as Map)['active'], isTrue);
      expect((update['designerProfile'] as Map)['location'], 'Harare');
      expect(update['isAgent'], isTrue);
      expect((update['agentProfile'] as Map)['type'], 'hair');
    });

    test('leaves out roles that were not chosen', () {
      final update = providerProfileUpdate(
        roles: [ProviderRole.designer],
        businessName: 'Ndlovu Designs',
        location: '',
      );

      expect(update.containsKey('shop'), isFalse);
      expect(update.containsKey('agentProfile'), isFalse);
      expect(update['providerMode'], isTrue);
    });

    test('never touches the verified flags', () {
      final update = providerProfileUpdate(
        roles: ProviderRole.values,
        businessName: 'X',
        location: '',
      );

      for (final key in ['shop', 'designerProfile', 'agentProfile']) {
        expect((update[key] as Map).containsKey('verified'), isFalse);
      }
    });
  });
}
