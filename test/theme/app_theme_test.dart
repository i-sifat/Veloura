import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dark theme exposes the renovated semantic palette', () {
    final colors = AppTheme.dark.extension<AppColors>();

    expect(colors, isNotNull);
    expect(colors!.background.toARGB32(), 0xFF090B12);
    expect(colors.surface.toARGB32(), 0xFF131722);
    expect(colors.card.toARGB32(), 0xFF1A2030);
    expect(colors.primary.toARGB32(), 0xFFFF4D7D);
    expect(colors.primaryPressed.toARGB32(), 0xFFE63B6A);
    expect(colors.textPrimary.toARGB32(), 0xFFF7F8FB);
    expect(colors.textSecondary.toARGB32(), 0xFFA7B0C0);
  });
}
