import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/features/dice/presentation/widgets/dice_cube.dart';

void main() {
  test('visible faces are culled and sorted nearest last', () {
    for (final rotation in [
      (0.2, 0.3),
      (0.7, -0.4),
      (-0.5, 1.1),
      (math.pi / 2, math.pi / 4),
    ]) {
      final faces = DiceCube.visibleFaces(
        rotationX: rotation.$1,
        rotationY: rotation.$2,
      );
      expect(faces, isNotEmpty);
      expect(faces.length, lessThanOrEqualTo(3));
      expect(faces.every((face) => face.depth > 0), isTrue);
      for (var index = 1; index < faces.length; index++) {
        expect(faces[index].depth, greaterThanOrEqualTo(faces[index - 1].depth));
      }
    }
  });

  test('visible-face brightness respects the ambient floor', () {
    for (var step = 0; step <= 20; step++) {
      final faces = DiceCube.visibleFaces(
        rotationX: step * math.pi / 20,
        rotationY: step * math.pi / 30,
      );
      expect(
        faces.every(
          (face) => face.brightness >= 0.42 && face.brightness <= 1,
        ),
        isTrue,
      );
    }
  });
}
