import 'package:flutter/services.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/positions/domain/intimacy_position.dart';
import 'package:veloura/features/positions/domain/position_repository.dart';
import 'package:veloura/features/positions/domain/position_zone.dart';

/// Discovers all position images dynamically from Flutter's asset manifest.
class PositionRepositoryAsset implements PositionRepository {
  @override
  Future<AppResult<List<IntimacyPosition>>> loadAll() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final paths = manifest
          .listAssets()
          .where((path) => path.startsWith('assets/Positions/'))
          .where((path) {
            final lower = path.toLowerCase();
            return lower.endsWith('.jpg') ||
                lower.endsWith('.jpeg') ||
                lower.endsWith('.png') ||
                lower.endsWith('.webp');
          })
          .toList()
        ..sort();
      final positions = <IntimacyPosition>[
        for (var index = 0; index < paths.length; index++)
          _fromPath(paths[index], index),
      ];
      return AppResult.success(positions);
    } on Object catch (error) {
      return AppResult.failure('Positions could not be loaded.', error);
    }
  }

  IntimacyPosition _fromPath(String path, int index) {
    final zone = PositionZone.values[index % PositionZone.values.length];
    final raw = path.split('/').last.replaceFirst(RegExp(r'\.[^.]+$'), '');
    final withoutPrefix = raw.replaceFirst(RegExp(r'^imgi_\d+_'), '');
    final cleaned = withoutPrefix
        .replaceAll(RegExp(r'[-_]+'), ' ')
        .replaceAll(RegExp(r'\b(scaled|sex|sexual|position|1024x724)\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final name = cleaned.isEmpty
        ? 'Position ${index + 1}'
        : cleaned
              .split(' ')
              .map((word) => word.isEmpty
                  ? word
                  : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
              .join(' ');
    final heatMin = zone == PositionZone.wild ? 4 : 1 + (index ~/ 48).clamp(0, 3);
    return IntimacyPosition(
      id: 'asset_pos_${index + 1}',
      zone: zone,
      name: name,
      setup: _setupFor(zone),
      heatMin: heatMin,
      isPremium: zone == PositionZone.wild,
      art: path,
    );
  }

  String _setupFor(PositionZone zone) => switch (zone) {
    PositionZone.close => 'Move face to face and stay close.',
    PositionZone.above => 'Let your partner settle above and lead.',
    PositionZone.behind => 'Move behind your partner and hold them close.',
    PositionZone.seated => 'Get comfortable seated together and find balance.',
    PositionZone.standing => 'Stand close together with steady support.',
    PositionZone.wild => 'Take your time and support each other fully.',
  };
}
