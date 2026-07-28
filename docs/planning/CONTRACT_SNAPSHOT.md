# Foundation Contract Snapshot

This is the Phase 1 contract of record for downstream module work. Copy these definitions into module implementation context and do not silently fork them.

## `ContentCategory`

```dart
enum ContentCategory {
  relationship,
  fantasy,
  memories,
  deepTalk,
  playful,
  romance,
  adventure,
  funny,
  future,
  daily,
}
```

## `Difficulty`

```dart
enum Difficulty { cute, romantic, spicy, extreme }
```

## `ContentItem`

```dart
abstract interface class ContentItem {
  String get id;
  ContentCategory get category;
  Difficulty get difficulty;
  bool get favorite;
  DateTime get createdAt;
}
```

## `ContentRepository<T>`

```dart
abstract interface class ContentRepository<T extends ContentItem> {
  Future<AppResult<List<T>>> getAll();
  Future<AppResult<List<T>>> getByCategory(ContentCategory category);
  Future<AppResult<List<T>>> getFavorites();
  Future<AppResult<T>> toggleFavorite(String id);
  Future<AppResult<T>> getRandom({ContentCategory? category});
  Future<AppResult<List<T>>> search(String query);
}
```

## `AppResult<T>`

```dart
sealed class AppResult<T> {
  const AppResult();
  const factory AppResult.success(T value) = AppSuccess<T>;
  const factory AppResult.failure(String message, [Object? cause]) = AppFailure<T>;
}

final class AppSuccess<T> extends AppResult<T> {
  const AppSuccess(this.value);
  final T value;
}

final class AppFailure<T> extends AppResult<T> {
  const AppFailure(this.message, [this.cause]);
  final String message;
  final Object? cause;
}
```

## Change protocol

Any change to these definitions must update this file in the same commit and call out migration impact in the PR description.
