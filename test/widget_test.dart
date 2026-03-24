import 'package:flutter_test/flutter_test.dart';
import 'package:algo_canvas/app.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const AlgoCanvasApp());
    expect(find.text('Algo Canvas'), findsOneWidget);
  });
}
