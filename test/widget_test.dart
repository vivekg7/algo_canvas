import 'package:flutter_test/flutter_test.dart';
import 'package:algo_canvas/app.dart';

void main() {
  testWidgets('App launches with home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AlgoCanvasApp());
    expect(find.text('Algo Canvas'), findsOneWidget);
    expect(find.text('Quick Sort'), findsOneWidget);
  });
}
