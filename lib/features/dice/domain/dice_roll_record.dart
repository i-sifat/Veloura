/// One persisted outcome from the Dice game.
class DiceRollRecord {
  const DiceRollRecord({
    required this.id,
    required this.action,
    required this.body,
    required this.createdAt,
    this.extra,
    this.favorite = false,
  });

  final String id;
  final String action;
  final String body;
  final String? extra;
  final DateTime createdAt;
  final bool favorite;

  /// User-facing combination text.
  String get summary => [action, body, if (extra != null) extra!].join(' • ');

  DiceRollRecord copyWith({bool? favorite}) => DiceRollRecord(
    id: id,
    action: action,
    body: body,
    extra: extra,
    createdAt: createdAt,
    favorite: favorite ?? this.favorite,
  );
}
