import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labaflow_mobile/widgets/shared_widgets.dart';

void main() {
  testWidgets('password visibility toggles without clearing text', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PasswordInputField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
      ),
    ));

    await tester.enterText(find.byType(TextField), 'laundry-secret');
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isFalse);
    expect(controller.text, 'laundry-secret');
    expect(find.byTooltip('Hide password'), findsOneWidget);
  });
}
