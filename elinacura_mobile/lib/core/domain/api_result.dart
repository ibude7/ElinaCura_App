/// Typed API outcome — surfaces failures instead of silent empty states.
sealed class ApiResult<T> {
  const ApiResult();

  bool get isSuccess => this is ApiSuccess<T>;
  bool get isFailure => this is ApiFailure<T>;

  T? get valueOrNull => switch (this) {
        ApiSuccess<T>(:final value) => value,
        _ => null,
      };

  String? get errorMessage => switch (this) {
        ApiFailure<T>(:final message) => message,
        _ => null,
      };

  R when<R>({
    required R Function(T value) success,
    required R Function(String message, Object? error) failure,
  }) =>
      switch (this) {
        ApiSuccess<T>(:final value) => success(value),
        ApiFailure<T>(:final message, :final error) => failure(message, error),
      };
}

final class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.value);
  final T value;
}

final class ApiFailure<T> extends ApiResult<T> {
  const ApiFailure(this.message, [this.error]);
  final String message;
  final Object? error;
}
