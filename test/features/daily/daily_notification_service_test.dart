import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/features/daily/data/daily_notification_service.dart';

void main() {
  test('permission denial is returned without throwing', () async {
    const service = NoopDailyNotificationService(permissionGranted: false);

    expect(await service.requestPermission(), isFalse);
    await expectLater(service.cancel(), completes);
  });
}
