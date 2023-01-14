import '../base_document.dart';
import '../partition/partition_key.dart';
import '../partition/partition_key_spec.dart';
import 'batch_operation.dart';
import 'batch_operation_types.dart';

/// Batch operation for upserting a document in the target container.
class BatchOperationUpsert<T extends BaseDocument>
    extends BatchOperationOnItem<T> {
  /// Creates a batch operation for upserting document [item].
  BatchOperationUpsert(T item,
      {PartitionKeySpec? partitionKeySpec, PartitionKey? partitionKey})
      : super(item,
            partitionKeySpec: partitionKeySpec, partitionKey: partitionKey);

  @override
  final BatchOperationType type = BatchOperationType.upsert;
}
