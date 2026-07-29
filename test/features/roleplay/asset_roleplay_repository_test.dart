import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/roleplay/data/asset_roleplay_repository.dart';
import 'package:veloura/features/roleplay/domain/roleplay_story.dart';
import 'package:veloura/models/difficulty.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('loads the balanced 42-story content pack', () async {
    final repository = AssetRoleplayRepository(
      await SharedPreferences.getInstance(),
    );

    final result = await repository.getAll();
    final stories = switch (result) {
      AppSuccess<List<RoleplayStory>>(:final value) => value,
      AppFailure<List<RoleplayStory>>(:final message) => fail(message),
    };

    expect(stories, hasLength(42));
    for (final category in RoleplayCategory.values) {
      expect(
        stories.where((story) => story.roleplayCategory == category),
        hasLength(14),
      );
    }
    expect(stories.every((story) => story.twists.length >= 2), isTrue);
    expect(stories.where((story) => story.premium), hasLength(18));
  });

  test('filters category, tier, and premium access together', () async {
    final repository = AssetRoleplayRepository(
      await SharedPreferences.getInstance(),
    );

    final stories = await repository.getFiltered(
      category: RoleplayCategory.fantasy,
      difficulty: Difficulty.spicy,
      includePremium: false,
    );
    final premiumStories = await repository.getFiltered(
      category: RoleplayCategory.fantasy,
      difficulty: Difficulty.spicy,
      includePremium: true,
    );

    expect(stories, isEmpty);
    expect(premiumStories, hasLength(4));
  });

  test('persists favorite story ids', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = AssetRoleplayRepository(preferences);

    final result = await repository.toggleFavorite('rp_0001');
    expect(result, isA<AppSuccess<RoleplayStory>>());
    expect(preferences.getStringList('roleplay_favorites'), ['rp_0001']);
  });
}
