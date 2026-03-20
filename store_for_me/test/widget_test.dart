import 'package:flutter_test/flutter_test.dart';
import 'package:store_for_me/main.dart';

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    await tester.pumpWidget(const ShopRadarApp());
  });
}
