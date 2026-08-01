import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/features/cards/domain/challenge_item.dart';
import 'package:veloura/features/conversation/domain/conversation_item.dart';
import 'package:veloura/features/truth_dare/domain/truth_dare_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Truth or Dare pack has 500 balanced, uniquely worded cards', () async {
    final raw = await rootBundle.loadString(
      'lib/features/truth_dare/data/truth_dare_seed.json',
    );
    final items = (jsonDecode(raw) as List<dynamic>)
        .map((value) => TruthDareItem.fromJson(value as Map<String, Object?>))
        .toList();

    expect(items, hasLength(500));
    expect(items.map((item) => item.id).toSet(), hasLength(500));
    expect(items.map((item) => item.prompt).toSet(), hasLength(500));
    expect(
      items.where((item) => item.kind == TruthDareKind.truth),
      hasLength(250),
    );
    expect(
      items.where((item) => item.kind == TruthDareKind.dare),
      hasLength(250),
    );
  });

  test('Challenge pack has exactly eight categories with 32 cards each', () async {
    final raw = await rootBundle.loadString(
      'lib/features/cards/data/challenge_seed.json',
    );
    final items = (jsonDecode(raw) as List<dynamic>)
        .map((value) => ChallengeItem.fromJson(value as Map<String, Object?>))
        .toList();

    expect(items, hasLength(256));
    expect(items.map((item) => item.id).toSet(), hasLength(256));
    for (final category in ChallengeCategory.values) {
      expect(
        items.where((item) => item.challengeCategory == category),
        hasLength(32),
      );
    }
  });

  test('Conversation pack has 75 unique prompts, 15 per category', () async {
    final raw = await rootBundle.loadString(
      'lib/features/conversation/data/conversation_seed.json',
    );
    final items = (jsonDecode(raw) as List<dynamic>)
        .map((value) =>
            ConversationItem.fromJson(value as Map<String, Object?>))
        .toList();

    expect(items, hasLength(75));
    expect(items.map((item) => item.id).toSet(), hasLength(75));
    expect(items.map((item) => item.prompt).toSet(), hasLength(75));
    for (final category in ConversationCategory.values) {
      expect(
        items.where((item) => item.conversationCategory == category),
        hasLength(15),
      );
    }
  });
}
