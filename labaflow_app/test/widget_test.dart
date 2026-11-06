// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:labaflow_app/main.dart';

void main() {
  testWidgets('application starts with the LabaFlow laundry identity', (tester) async {
    await tester.pumpWidget(const LabaFlowApp(home: _SmokeHome()));
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'LabaFlow');
    expect(app.theme?.brightness, Brightness.light);
    expect(find.text('LabaFlow application'), findsOneWidget);
  });
}

class _SmokeHome extends StatelessWidget {
  const _SmokeHome();

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('LabaFlow application'));
}
