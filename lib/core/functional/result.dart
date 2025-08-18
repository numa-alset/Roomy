sealed class Result<E, T> {
  const Result();
  R fold<R>(R Function(E) onErr, R Function(T) onOk);
  bool get isOk => this is Ok<E, T>;
  T? get okOrNull => this is Ok<E, T> ? (this as Ok<E, T>).value : null;
  E? get errOrNull => this is Err<E, T> ? (this as Err<E, T>).error : null;
}

class Ok<E, T> extends Result<E, T> {
  final T value;
  const Ok(this.value);
  @override
  R fold<R>(R Function(E) onErr, R Function(T) onOk) => onOk(value);
}

class Err<E, T> extends Result<E, T> {
  final E error;
  const Err(this.error);
  @override
  R fold<R>(R Function(E) onErr, R Function(T) onOk) => onErr(error);
}
