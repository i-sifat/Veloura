import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/features/positions/domain/heat_ladder.dart';

void main() {
  test('heat rises every two rounds and respects caps', () {
    expect(heatFor(0, premium: false, softened: false), 1);
    expect(heatFor(2, premium: false, softened: false), 2);
    expect(heatFor(8, premium: false, softened: false), 3);
    expect(heatFor(8, premium: true, softened: false), 5);
    expect(heatFor(8, premium: true, softened: true), 2);
  });
}
