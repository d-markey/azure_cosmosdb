import '../../base_document.dart';
import '../../partition/partition_key.dart';
import '../batch_operation.dart';
import '../batch_operation_type.dart';

/// Batch operation for deleting a document from the target container.
class BatchOperationDelete extends BatchOperation {
  /// Creates a batch operation for deleting document with [id] and [partitionKey].
  BatchOperationDelete(this.id, {PartitionKey? partitionKey})
      : super(partitionKey: partitionKey);

  @override
  final BatchOperationType type = BatchOperationType.delete;

  /// The target document [id].
  final String id;

  @override
  JSonMessage toJson() => super.toJson()
    ..addAll({
      'id': id,
    });
}
