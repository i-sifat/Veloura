import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/features/roleplay/presentation/roleplay_screen.dart';
import 'package:veloura/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads picker and enters a story session', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const RoleplayScreen(),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Roleplay Stories'), findsOneWidget);
    expect(find.text('Story packs'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('House Owner & Robber'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('House Owner & Robber'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Assign roles'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Assign roles'));
    await tester.pumpAndSettle();

    expect(find.text('Partner one'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Finish story'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Finish story'), findsOneWidget);
  });
}
