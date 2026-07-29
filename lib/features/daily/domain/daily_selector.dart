import 'package:veloura/features/daily/domain/daily_challenge.dart';

/// Stable date-seeded selection that does not depend on Dart's hashCode.
class DailySelector {
  const DailySelector();

  DailyChallenge select({
    required List<DailyChallenge> pool,
    required String deviceSeed,
    required DateTime date,
  }) {
    if (pool.isEmpty) throw StateError('Daily challenge pool is empty.');
    final day = dateOnly(date);
    final seed = '$deviceSeed|${day.year}-${day.month}-${day.day}';
    return pool[_fnv1a(seed) % pool.length];
  }

  int _fnv1a(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

String dateKey(DateTime value) {
  final day = dateOnly(value);
  return '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}
