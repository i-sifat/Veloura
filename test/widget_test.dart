import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/main.dart';

void main() {
  testWidgets('Veloura launches with an empty dark scaffold', (tester) async {
    await tester.pumpWidget(const VelouraApp());

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Flutter Demo Home Page'), findsNothing);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final context = tester.element(find.byWidget(scaffold));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
