import 'package:veloura/features/dice/data/dice_roll_record_adapter.dart';
import 'package:veloura/services/hive_adapter_registry.dart';

/// Registers Dice-owned Hive adapters.
void registerDiceAdapters(HiveAdapterRegistry registry) {
  registry.register(DiceRollRecordAdapter());
}
