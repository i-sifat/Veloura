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
    await tester.pumpAndSettle();

    expect(find.text('Roleplay Stories'), findsOneWidget);
    expect(find.text('Story packs'), findsOneWidget);

    await tester.tap(find.text('The Moonlit Masquerade'));
    await tester.pumpAndSettle();
    final assignRoles = find.text('Assign roles');
    await tester.ensureVisible(assignRoles);
    await tester.pumpAndSettle();
    await tester.tap(assignRoles);
    await tester.pumpAndSettle();

    expect(find.text('Partner one'), findsOneWidget);
    expect(find.text('Reveal next twist'), findsOneWidget);
  });
}
