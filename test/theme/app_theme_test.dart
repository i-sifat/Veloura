import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dark theme exposes the exact semantic palette', () {
    final colors = AppTheme.dark.extension<AppColors>();

    expect(colors, isNotNull);
    expect(colors!.background.toARGB32(), 0xFF120B16);
    expect(colors.primary.toARGB32(), 0xFFFF4D6D);
    expect(colors.card.toARGB32(), 0xFF2A1D31);
    expect(colors.textSecondary.toARGB32(), 0xFFB9B3C5);
  });
}
