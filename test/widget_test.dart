import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_mobile_app/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CoreFlowMobileApp(isLoggedIn: false));
  });
}

