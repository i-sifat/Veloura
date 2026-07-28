/// Repository-boundary result that prevents data exceptions reaching the UI.
sealed class AppResult<T> {
  const AppResult();

  /// Creates a successful result.
  const factory AppResult.success(T value) = AppSuccess<T>;

  /// Creates a failed result with a safe user-facing message.
  const factory AppResult.failure(String message, [Object? cause]) =
      AppFailure<T>;

  /// Transforms the success value while preserving failures.
  AppResult<R> map<R>(R Function(T value) transform) => switch (this) {
    AppSuccess<T>(:final value) => AppResult.success(transform(value)),
    AppFailure<T>(:final message, :final cause) =>
      AppResult.failure(message, cause),
  };
}

/// Successful [AppResult].
final class AppSuccess<T> extends AppResult<T> {
  const AppSuccess(this.value);

  /// Returned value.
  final T value;
}

/// Failed [AppResult].
final class AppFailure<T> extends AppResult<T> {
  const AppFailure(this.message, [this.cause]);

  /// Safe message suitable for presentation.
  final String message;

  /// Optional internal cause for diagnostics.
  final Object? cause;
}
