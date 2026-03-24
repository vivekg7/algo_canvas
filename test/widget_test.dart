import 'package:flutter_test/flutter_test.dart';
import 'package:algo_canvas/app.dart';
import 'package:algo_canvas/theme/theme_controller.dart';

void main() {
  testWidgets('App launches with home screen', (WidgetTester tester) async {
    final themeController = ThemeController();
    await tester.pumpWidget(AlgoCanvasApp(themeController: themeController));
    expect(find.text('Algo Canvas'), findsOneWidget);
    expect(find.text('Quick Sort'), findsOneWidget);
  });
}
