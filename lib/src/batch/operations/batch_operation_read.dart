import '../../base_document.dart';
import '../../partition/partition_key.dart';
import '../batch_operation.dart';
import '../batch_operation_type.dart';

/// Batch operation for loading a document from the target container.
class BatchOperationRead<T extends BaseDocument>
    extends BatchOperationOnType<T> {
  /// Creates a batch operation for loading document with [id] and [partitionKey].
  BatchOperationRead(this.id, {PartitionKey? partitionKey})
      : super(partitionKey: partitionKey);

  @override
  final BatchOperationType type = BatchOperationType.read;

  /// The target document [id].
  final String id;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'id': id,
    });
}
