import '../../base_document.dart';
import '../../partition/partition_key.dart';
import '../../partition/partition_key_spec.dart';
import '../batch_operation.dart';
import '../batch_operation_type.dart';

/// Batch operation for adding a document in the target container.
class BatchOperationCreate<T extends BaseDocument>
    extends BatchOperationOnItem<T> {
  /// Creates a batch operation for adding document [item].
  BatchOperationCreate(T item,
      {PartitionKeySpec? partitionKeySpec, PartitionKey? partitionKey})
      : super(item,
            partitionKeySpec: partitionKeySpec, partitionKey: partitionKey);

  @override
  final BatchOperationType type = BatchOperationType.create;
}
