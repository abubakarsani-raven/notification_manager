// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing


import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:notification_manager/notification_manager.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('notification manager initialization test', (WidgetTester tester) async {
    final NotificationManager plugin = NotificationManager();
    final bool initialized = await plugin.initialize();
    // Test that initialization succeeds
    expect(initialized, true);
  });
}
