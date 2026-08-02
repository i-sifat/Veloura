import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/roleplay/data/asset_roleplay_repository.dart';
import 'package:veloura/features/roleplay/domain/roleplay_story.dart';
import 'package:veloura/models/difficulty.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('loads the roleplay content pack', () async {
    final repository = AssetRoleplayRepository(
      await SharedPreferences.getInstance(),
    );

    final result = await repository.getAll();
    final stories = switch (result) {
      AppSuccess<List<RoleplayStory>>(:final value) => value,
      AppFailure<List<RoleplayStory>>(:final message) => fail(message),
    };

    expect(stories, hasLength(92));
    expect(
      stories.where((story) => story.roleplayCategory == RoleplayCategory.romance),
      hasLength(82),
    );
    expect(
      stories.where((story) => story.roleplayCategory == RoleplayCategory.adventure),
      hasLength(10),
    );
    expect(stories.every((story) => story.setting.isNotEmpty), isTrue);
    expect(stories.where((story) => story.premium), hasLength(44));
  });

  test('filters category, tier, and premium access together', () async {
    final repository = AssetRoleplayRepository(
      await SharedPreferences.getInstance(),
    );

    final stories = await repository.getFiltered(
      category: RoleplayCategory.romance,
      difficulty: Difficulty.spicy,
      includePremium: false,
    );
    final premiumStories = await repository.getFiltered(
      category: RoleplayCategory.romance,
      difficulty: Difficulty.spicy,
      includePremium: true,
    );

    expect(stories, isNotEmpty);
    expect(premiumStories, hasLength(greaterThan(stories.length)));
  });

  test('persists favorite story ids', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = AssetRoleplayRepository(preferences);

    final result = await repository.toggleFavorite('rp_0043');
    expect(result, isA<AppSuccess<RoleplayStory>>());
    expect(preferences.getStringList('roleplay_favorites'), ['rp_0043']);
  });
}
