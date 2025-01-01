abstract class OptionOrNull<T> {
  T? get value;
}

class Value<T> extends OptionOrNull<T> {
  @override
  final T value;

  Value(this.value);
}

class Nullable<T> extends OptionOrNull<T> {
  @override
  final T? value = null;
}
