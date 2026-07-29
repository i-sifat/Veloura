import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/features/roleplay/domain/roleplay_story.dart';
import 'package:veloura/models/content_category.dart';
import 'package:veloura/models/difficulty.dart';

void main() {
  test('parses a complete roleplay story and maps shared category', () {
    final story = RoleplayStory.fromJson({
      'id': 'rp_test',
      'title': 'Test Story',
      'category': 'fantasy',
      'tier': 'romantic',
      'characterA': {'name': 'A', 'description': 'First role'},
      'characterB': {'name': 'B', 'description': 'Second role'},
      'setting': 'A test setting',
      'goal': 'Complete the scene',
      'twists': ['First twist', 'Second twist'],
      'estimatedDuration': '15 min',
      'packId': 'test_pack',
      'packTitle': 'Test Pack',
      'premium': false,
      'createdAt': '2026-07-29T00:00:00Z',
    });

    expect(story.id, 'rp_test');
    expect(story.category, ContentCategory.fantasy);
    expect(story.difficulty, Difficulty.romantic);
    expect(story.twists, hasLength(2));
    expect(story.characterA.name, 'A');
  });

  test('copyWith changes only favorite state', () {
    final story = RoleplayStory(
      id: 'rp_test',
      title: 'Test Story',
      roleplayCategory: RoleplayCategory.adventure,
      difficulty: Difficulty.cute,
      characterA: const RoleplayCharacter(
        name: 'A',
        description: 'First',
      ),
      characterB: const RoleplayCharacter(
        name: 'B',
        description: 'Second',
      ),
      setting: 'Setting',
      goal: 'Goal',
      twists: const ['Twist'],
      estimatedDuration: '10 min',
      packId: 'pack',
      packTitle: 'Pack',
      premium: false,
      createdAt: DateTime(2026),
    );

    final updated = story.copyWith(favorite: true);
    expect(updated.favorite, isTrue);
    expect(updated.title, story.title);
    expect(updated.characterB.name, story.characterB.name);
  });
}
