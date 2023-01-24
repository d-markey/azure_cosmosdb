import '../../base_document.dart';
import '../../partition/partition_key.dart';
import '../../partition/partition_key_spec.dart';
import '../batch_operation.dart';
import '../batch_operation_type.dart';

/// Batch operation for replacing a document in the target container.
class BatchOperationReplace<T extends BaseDocument>
    extends BatchOperationOnItem<T> {
  /// Creates a batch operation for replacing document [item].
  BatchOperationReplace(T item,
      {PartitionKeySpec? partitionKeySpec, PartitionKey? partitionKey})
      : super(item,
            partitionKeySpec: partitionKeySpec, partitionKey: partitionKey);

  @override
  final BatchOperationType type = BatchOperationType.replace;
}
