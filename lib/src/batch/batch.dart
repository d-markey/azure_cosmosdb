import '../base_document.dart';
import '../client/http_status_codes.dart';
import '../cosmos_db_container.dart';
import '../partition/partition_key.dart';
import '../permissions/cosmos_db_permission.dart';
import 'batch_operation.dart';
import 'batch_operation_create.dart';
import 'batch_operation_delete.dart';
import 'batch_operation_read.dart';
import 'batch_operation_upsert.dart';
import 'batch_response.dart';

/// Base class for a transactional batch.
abstract class Batch extends SpecialDocument {
  /// The [container] this batch instance is attached to.
  CosmosDbContainer get container;

  /// If `true`, processing will continue after an error. Otherwise, processing is stopped
  /// and subsequent operations fail with a 424 [HttpStatusCode.failedDependency] status
  /// code.
  bool get continueOnError;

  /// If `true`, modifications are persisted to the [container] atomically. If an error
  /// occurs during processing, no modifications are persisted and all other operations
  /// fail with a 424 [HttpStatusCode.failedDependency] status code.
  bool get isAtomic;

  /// If `true`, operations registered with this batch may target multiple partition keys.
  /// Operations will be grouped by partition keys when [execute] is called. Implies
  /// [continueOnError] = `true` and [isAtomic] = `false`.
  bool get isCrossPartition;

  /// The number of operations in this batch instance.
  int get length;

  /// The list of operations registered with this batch instance.
  Iterable<BatchOperation> get operations;

  /// Recycles this batch instance for reuse. This method clears the list of operations.
  void recycle();

  /// Adds the specified [BatchOperation] to this batch instance.
  void add(BatchOperation op);

  /// Adds a [BatchOperationCreate] to this batch instance.
  void create<T extends BaseDocument>(T item, {PartitionKey? partitionKey}) =>
      add(BatchOperationCreate<T>(item,
          partitionKeySpec: container.partitionKeySpec,
          partitionKey: partitionKey));

  /// Adds a [BatchOperationUpsert] to this batch instance.
  void upsert<T extends BaseDocument>(T item, {PartitionKey? partitionKey}) =>
      add(BatchOperationUpsert<T>(item,
          partitionKeySpec: container.partitionKeySpec,
          partitionKey: partitionKey));

  /// Adds a [BatchOperationRead] to this batch instance.
  void read<T extends BaseDocument>(String id,
          {required PartitionKey partitionKey}) =>
      add(BatchOperationRead<T>(id, partitionKey: partitionKey));

  /// Adds a [BatchOperationDelete] to this batch instance.
  void delete(String id, {required PartitionKey partitionKey}) =>
      add(BatchOperationDelete(id, partitionKey: partitionKey));

  /// Executes the [BatchOperation]s registered in this batch instance.
  Future<BatchResponse> execute({CosmosDbPermission? permission});
}
