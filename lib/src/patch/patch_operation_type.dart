/// Constants for patch operations.
class PatchOperationType {
  const PatchOperationType._(this.name);

  /// The patch operation's [name].
  final String name;

  /// Constant for "add" operation.
  static const add = PatchOperationType._('add');

  /// Constant for "set" operation.
  static const set = PatchOperationType._('set');

  /// Constant for "replace" operation.
  static const replace = PatchOperationType._('replace');

  /// Constant for "remove" operation.
  static const remove = PatchOperationType._('remove');

  /// Constant for "incr" operation.
  static const incr = PatchOperationType._('incr');
}
