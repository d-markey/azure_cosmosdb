import '../../base_document.dart';
import '../../partition/partition_key.dart';
import '../../patch/patch.dart';
import '../batch_operation.dart';
import '../batch_operation_type.dart';

/// Batch operation for patching documents in the target container.
class BatchOperationPatch<T extends BaseDocument>
    extends BatchOperationOnType<T> implements Patch {
  /// Creates a batch operation for patching document with [id].
  BatchOperationPatch(this.id, {PartitionKey? partitionKey})
      : super(partitionKey: partitionKey);

  @override
  final BatchOperationType type = BatchOperationType.patch;

  /// The target document [id].
  @override
  final String id;

  final Patch _patch = Patch();

  @override
  void add(String path, value) => _patch.add(path, value);

  @override
  void decrement(String path, [num value = 1]) => _patch.decrement(path, value);

  @override
  void increment(String path, [num value = 1]) => _patch.increment(path, value);

  @override
  void remove(String path) => _patch.remove(path);

  @override
  void replace(String path, value) => _patch.replace(path, value);

  @override
  void set(String path, value) => _patch.set(path, value);

  @override
  void setCondition(String condition) => _patch.setCondition(condition);

  @override
  void withParam(String name, value) => _patch.withParam(name, value);

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'id': id,
      'resourceBody': _patch.toJson(),
    });
}
