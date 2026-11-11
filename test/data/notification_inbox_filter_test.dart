import 'package:banigoba/data/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationService.isInboxRow', () {
    test('hides AI job status notifications from the inbox', () {
      expect(NotificationService.isInboxRow({'type': 'ai_job'}), isFalse);
    });

    test('keeps social and shop notifications in the inbox', () {
      for (final type in ['follow_request', 'follow_accepted', 'like']) {
        expect(NotificationService.isInboxRow({'type': type}), isTrue);
      }
    });
  });
}
