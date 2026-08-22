import 'package:flutter_test/flutter_test.dart';

import 'package:batsh/core/notifications/notification_destination.dart';
import 'package:batsh/features/auth/domain/profile.dart';

void main() {
  test('brief notifications resolve to the viewer role destination', () {
    expect(
      notificationDestination(
        entityType: 'brief',
        entityId: 'brief-1',
        role: UserRole.homeowner,
      ),
      '/h/requests/brief-1',
    );
    expect(
      notificationDestination(
        entityType: 'brief',
        entityId: 'brief-1',
        role: UserRole.contractor,
      ),
      '/c/dashboard/post/brief-1',
    );
  });

  test('community notifications resolve to the viewer role destination', () {
    expect(
      notificationDestination(
        entityType: 'post',
        entityId: 'post-1',
        role: UserRole.homeowner,
      ),
      '/h/explore/post/post-1',
    );
    expect(
      notificationDestination(
        entityType: 'post',
        entityId: 'post-1',
        role: UserRole.contractor,
      ),
      '/c/explore/post/post-1',
    );
  });

  test('malformed or unsupported payloads fall back safely', () {
    expect(
      notificationDestination(
        entityType: 'unknown',
        entityId: 'post-1',
        role: UserRole.homeowner,
      ),
      isNull,
    );
    expect(
      notificationDestination(
        entityType: 'post',
        entityId: ' ',
        role: UserRole.homeowner,
      ),
      isNull,
    );
    expect(
      notificationDestination(
        entityType: 'post',
        entityId: 'post-1',
        role: null,
      ),
      isNull,
    );
  });
}
