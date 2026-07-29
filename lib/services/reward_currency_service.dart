import 'package:shared_preferences/shared_preferences.dart';

/// Minimal shared currency contract introduced by Daily and reused in Phase 6.
abstract interface class RewardCurrencyService {
  Future<int> balance();
  Future<int> award(int amount);
}

/// Local-first "sparks" balance. Premium must reuse this service, not fork it.
class PreferencesRewardCurrencyService implements RewardCurrencyService {
  PreferencesRewardCurrencyService(this.preferences);

  final SharedPreferences preferences;
  static const _balanceKey = 'reward_currency_balance';

  @override
  Future<int> balance() async => preferences.getInt(_balanceKey) ?? 0;

  @override
  Future<int> award(int amount) async {
    final updated = (await balance()) + amount;
    await preferences.setInt(_balanceKey, updated);
    return updated;
  }
}
