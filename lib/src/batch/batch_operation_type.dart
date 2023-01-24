/// Constants for batch operation types.
class BatchOperationType {
  const BatchOperationType._(this.name);

  /// Name of the batch operation type.
  final String name;

  /// `Create` operation type.
  static const create = BatchOperationType._('Create');

  /// `Upsert` operation type.
  static const upsert = BatchOperationType._('Upsert');

  /// `Read` operation type.
  static const read = BatchOperationType._('Read');

  /// `Delete` operation type.
  static const delete = BatchOperationType._('Delete');

  /// `Replace` operation type.
  static const replace = BatchOperationType._('Replace');

  /// `Patch` operation type.
  static const patch = BatchOperationType._('Patch');
}
