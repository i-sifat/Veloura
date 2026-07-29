import 'package:veloura/features/positions/domain/position_zone.dart';

/// One image-backed position discovered from the bundled asset manifest.
class IntimacyPosition {
  const IntimacyPosition({
    required this.id,
    required this.zone,
    required this.name,
    required this.setup,
    required this.heatMin,
    required this.isPremium,
    required this.art,
  });

  final String id;
  final PositionZone zone;
  final String name;
  final String setup;
  final int heatMin;
  final bool isPremium;
  final String art;
}
