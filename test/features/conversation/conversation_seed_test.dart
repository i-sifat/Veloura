import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('prompt pack has no duplicate prompts, stays short, and covers every category', () async {
    final raw = await rootBundle.loadString(
      'lib/features/conversation/data/conversation_seed.json',
    );
    final entries = (jsonDecode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>();

    expect(entries, isNotEmpty);

    final prompts = entries.map((entry) => entry['prompt'] as String).toList();
    expect(
      prompts.toSet(),
      hasLength(prompts.length),
      reason: 'every prompt should be unique, not a shared stem with a swapped suffix',
    );

    for (final prompt in prompts) {
      expect(
        prompt.split(' ').length,
        lessThanOrEqualTo(18),
        reason: 'prompt should stay short and easy to read: "$prompt"',
      );
    }

    final categories = entries
        .map((entry) => entry['conversationCategory'] as String)
        .toSet();
    for (final category in ['deep', 'funny', 'romantic', 'future', 'rediscover']) {
      expect(categories, contains(category));
    }
  });
}
