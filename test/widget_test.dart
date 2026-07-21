import 'package:flutter_test/flutter_test.dart';
import 'package:pc_builder/main.dart';

void main() {
  testWidgets('PC Builder smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PcBuilderApp());
    expect(find.text('PC BUILDER'), findsAny);
  });
}
