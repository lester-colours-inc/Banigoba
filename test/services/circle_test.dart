// Verifies My Circle data and how it orders who a look can be sent to.
import 'package:banigoba/modules/social/services/circle_service.dart';
import 'package:banigoba/modules/social/widgets/forward_recipient_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

const _salon = ForwardRecipient(id: 's1', name: 'Glow Salon');
const _other = ForwardRecipient(id: 's2', name: 'Braids Bar');

void main() {
  test('splits recipients into My Circle first, then everyone else', () {
    final split = splitByCircle([_other, _salon], {'s1'});
    expect(split.circle.map((r) => r.id), ['s1']);
    expect(split.others.map((r) => r.id), ['s2']);
  });

  test('a recipient becomes a Circle member of the right kind', () {
    final member = _salon.toCircleMember(CircleKind.salon);
    expect(member.kind, CircleKind.salon);
    expect(member.toMap()['kind'], 'salon');
    expect(member.toMap()['name'], 'Glow Salon');
  });

  test('reads members back, skipping unknown kinds', () {
    expect(
      CircleMember.fromMap('d1', {'kind': 'designer', 'name': 'Rudo'})?.kind,
      CircleKind.designer,
    );
    expect(CircleMember.fromMap('x', {'kind': 'bakery'}), isNull);
  });

  test('every send-to kind maps to a Circle kind', () {
    expect(ForwardRecipientKind.salon.circleKind, CircleKind.salon);
    expect(ForwardRecipientKind.shop.circleKind, CircleKind.shop);
    expect(ForwardRecipientKind.designer.circleKind, CircleKind.designer);
  });
}
