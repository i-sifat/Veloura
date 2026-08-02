import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/features/positions/domain/session_intensity.dart';

void main() {
  test('intensity maps soft through hardcore across the heat ladder', () {
    expect(PositionSessionIntensity.forHeat(1), PositionSessionIntensity.soft);
    expect(PositionSessionIntensity.forHeat(2), PositionSessionIntensity.soft);
    expect(PositionSessionIntensity.forHeat(3), PositionSessionIntensity.fast);
    expect(
      PositionSessionIntensity.forHeat(4),
      PositionSessionIntensity.hardcore,
    );
    expect(
      PositionSessionIntensity.forHeat(5),
      PositionSessionIntensity.hardcore,
    );
  });

  test('session length grows with heat', () {
    expect(positionSessionSeconds(1), 60);
    expect(positionSessionSeconds(2), 60);
    expect(positionSessionSeconds(3), 90);
    expect(positionSessionSeconds(4), 120);
    expect(positionSessionSeconds(5), 120);
  });

  test('hardcore sessions pulse faster than soft ones', () {
    expect(
      PositionSessionIntensity.hardcore.beatPeriod,
      lessThan(PositionSessionIntensity.soft.beatPeriod),
    );
  });
}
