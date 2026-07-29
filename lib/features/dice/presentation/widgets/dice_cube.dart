import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:veloura/features/dice/presentation/widgets/die_face.dart';

/// A transform-composed six-face cube with live text faces.
class DiceCube extends StatelessWidget {
  const DiceCube({
    required this.faces,
    required this.rotationX,
    required this.rotationY,
    required this.size,
    this.blurSigma = 0,
    this.textOpacity = 1,
    super.key,
  }) : assert(faces.length == 6);

  final List<String> faces;
  final double rotationX;
  final double rotationY;
  final double size;
  final double blurSigma;
  final double textOpacity;

  static final vector.Vector3 _lightDirection =
      vector.Vector3(-0.35, -0.55, 0.76)..normalize();

  static final List<_FaceDefinition> _definitions = [
    _FaceDefinition(vector.Vector3(0, 0, 1), 0, 0),
    _FaceDefinition(vector.Vector3(0, 0, -1), math.pi, 0),
    _FaceDefinition(vector.Vector3(1, 0, 0), math.pi / 2, 0),
    _FaceDefinition(vector.Vector3(-1, 0, 0), -math.pi / 2, 0),
    _FaceDefinition(vector.Vector3(0, -1, 0), 0, math.pi / 2),
    _FaceDefinition(vector.Vector3(0, 1, 0), 0, -math.pi / 2),
  ];

  /// Computes the culled, farthest-first face order used by the renderer.
  static List<VisibleDieFace> visibleFaces({
    required double rotationX,
    required double rotationY,
  }) {
    final rotation = vector.Matrix4.identity()
      ..rotateX(rotationX)
      ..rotateY(rotationY);
    final visible = <VisibleDieFace>[];
    for (var index = 0; index < _definitions.length; index++) {
      final normal = rotation.transform3(
        vector.Vector3.copy(_definitions[index].normal),
      );
      if (normal.z <= 0.000001) continue;
      final lambert = math.max(0.0, normal.dot(_lightDirection));
      visible.add(
        VisibleDieFace(
          index: index,
          depth: normal.z,
          brightness: 0.42 + 0.58 * lambert,
        ),
      );
    }
    visible.sort((a, b) => a.depth.compareTo(b.depth));
    return visible;
  }

  @override
  Widget build(BuildContext context) {
    final visible = visibleFaces(rotationX: rotationX, rotationY: rotationY);
    final nearestIndex = visible.isEmpty ? -1 : visible.last.index;
    final half = size / 2;

    return RepaintBoundary(
      child: SizedBox.square(
        dimension: size,
        child: Transform(
          alignment: Alignment.center,
          transform: vector.Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateX(rotationX)
            ..rotateY(rotationY),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final face in visible)
                Positioned.fill(
                  child: Transform(
                    alignment: Alignment.center,
                    transform: vector.Matrix4.identity()
                      ..rotateY(_definitions[face.index].yaw)
                      ..rotateX(_definitions[face.index].pitch)
                      ..translate(0.0, 0.0, half),
                    child: DieFace(
                      label: faces[face.index],
                      size: size,
                      brightness: face.brightness,
                      blurSigma: blurSigma,
                      textOpacity: textOpacity,
                      includeSemantics: face.index == nearestIndex,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Testable culling, depth, and shading output for one visible face.
@immutable
class VisibleDieFace {
  const VisibleDieFace({
    required this.index,
    required this.depth,
    required this.brightness,
  });

  final int index;
  final double depth;
  final double brightness;
}

class _FaceDefinition {
  const _FaceDefinition(this.normal, this.yaw, this.pitch);

  final vector.Vector3 normal;
  final double yaw;
  final double pitch;
}
