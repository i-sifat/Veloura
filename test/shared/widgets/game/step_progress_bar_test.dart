import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/shared/widgets/game/step_progress_bar.dart';

void main() {
  testWidgets('renders one labeled dot per step', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StepProgressBar(stepCount: 3, activeStep: 2)),
      ),
    );

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  test('rejects an active step outside the valid range', () {
    expect(
      () => StepProgressBar(stepCount: 3, activeStep: 4),
      throwsA(isA<AssertionError>()),
    );
  });
}
