sealed class Result<T> {
  const Result();
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final AppFailure error;
  const Failure(this.error);
}

sealed class AppFailure {
  final String message;
  final Object? cause;
  const AppFailure(this.message, {this.cause});
}

class AuthFailure extends AppFailure {
  const AuthFailure(super.message, {super.cause});
}

class DbFailure extends AppFailure {
  const DbFailure(super.message, {super.cause});
}

class StorageFailure extends AppFailure {
  const StorageFailure(super.message, {super.cause});
}

class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message, {super.cause});
}
