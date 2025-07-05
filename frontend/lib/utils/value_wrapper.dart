/// A wrapper class to distinguish between an omitted value and an explicitly
/// passed null value, which is a common issue in `copyWith` methods.
class ValueWrapper<T> {
  final T value;
  const ValueWrapper(this.value);
}
