import '../_internal/_linq_extensions.dart';
import '../authorizations/cosmos_db_permission.dart';
import '../cosmos_db_container.dart';
import '../cosmos_db_exceptions.dart';
import '../partition/partition_key.dart';
import 'batch.dart';
import 'batch_operation.dart';
import 'batch_response.dart';
import 'transactional_batch.dart';

/// A cross-partition transactional batch. This class can handle operations targetting
/// multiple partition keys, and supports more than 100 operations. Atomic behavior is
/// not possible with this class, and [isAtomic] will always be `false`. Stopping on
/// error is also not possible with this implementation and [continueOnError] will
/// always be `true`.
class CrossPartitionBatch extends Batch {
  CrossPartitionBatch(CosmosDbContainer container, {PartitionKey? partitionKey})
      : super(container, partitionKey);

  /// Cross-partition batches always have [continueOnError] = `true`.
  @override
  final bool continueOnError = true;

  /// Cross-partition batches cannot be atomic and always have [isAtomic] = `false`.
  @override
  final bool isAtomic = false;

  @override
  final bool isCrossPartition = true;

  @override
  int get length => _ops.length;

  @override
  Iterable<BatchOperation> get operations => _ops.asIterable();

  final _ops = <BatchOperation>[];

  final _opsByPk = <PartitionKey, TransactionalBatch>{};

  @override
  void recycle() {
    _ops.clear();
    _opsByPk.clear();
  }

  @override
  void add(BatchOperation op) {
    final pk = op.partitionKey ?? partitionKey;
    if (pk == null) {
      throw PartitionKeyException('Missing partition key.');
    }
    TransactionalBatch? batch;
    final key = _opsByPk.keys.singleOrDefault((k) => k == pk);
    if (key == null) {
      batch = TransactionalBatch(
        container,
        continueOnError: true,
        partitionKey: partitionKey,
      );
      _opsByPk[pk] = batch;
    } else {
      batch = _opsByPk[key]!;
    }
    batch.add(op);
    _ops.add(op);
  }

  /// Executes the [BatchOperation]s registered in this batch instance. Operations are grouped
  /// by partition keys and sent to Cosmos DB in chunks of 100 operations per partition key.
  @override
  Future<BatchResponse> execute({CosmosDbPermission? permission}) async {
    var pending = 0;
    final futures = <Future>[];
    for (var batch in _opsByPk.values) {
      pending++;
      futures.add(
          batch.execute(permission: permission).whenComplete(() => pending--));
      while (pending > 2) {
        // throttle
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
    await Future.wait(futures);
    return BatchResponse()..addAll(_ops.map((o) => o.result!));
  }

  @override
  List<dynamic> toJson() => _ops.map((o) => o.toJson()).toList();
}
