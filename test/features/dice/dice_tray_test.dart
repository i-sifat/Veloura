import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/features/dice/presentation/widgets/dice_tray.dart';
import 'package:veloura/theme/app_theme.dart';

void main() {
  testWidgets('dice tray stays fixed height', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: DiceTray(onRoll: () {}, child: const SizedBox.expand()),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('dice-tray'))).height,
      DiceTray.height,
    );
  });

  testWidgets('dice tray is a tappable roll affordance', (tester) async {
    var rolls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: DiceTray(
            onRoll: () => rolls++,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('dice-tray')));
    expect(rolls, 1);
  });
}
