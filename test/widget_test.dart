// Basic smoke test for Los Chucos App
import 'package:flutter_test/flutter_test.dart';
import 'package:los_chucos_app/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LosChucosApp());

    // Verify the app loads (splash screen or login)
    await tester.pump();
  });
}
