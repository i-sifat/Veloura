# Veloura

Veloura is a private, playful couples app for building connection through games, conversations, challenges, and shared rituals.

The mobile app is built with Flutter and follows a local-first, feature-oriented clean architecture. Riverpod provides state management, `go_router` handles navigation, and Hive CE provides local persistence.

## Development

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

Generated `*.g.dart` and `*.freezed.dart` files are committed to source control so local builds and CI use the same generated output. Build products and tool caches remain ignored.
