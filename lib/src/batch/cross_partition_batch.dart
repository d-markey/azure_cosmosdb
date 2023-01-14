import '../_internal/_linq_extensions.dart';
import '../cosmos_db_container.dart';
import '../cosmos_db_exceptions.dart';
import '../partition/partition_key.dart';
import '../permissions/cosmos_db_permission.dart';
import 'batch.dart';
import 'batch_operation.dart';
import 'batch_response.dart';
import 'transactional_batch.dart';

/// A cross-partition transactional batch. This class can handle operations targetting
/// multiple partition keys, and supports more than 100 operations.
class CrossPartitionBatch extends Batch {
  CrossPartitionBatch(this.container);

  @override
  final CosmosDbContainer container;

  @override
  final bool continueOnError = true;

  @override
  final bool isAtomic = false;

  @override
  final bool isCrossPartition = false;

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
    final pk = op.partitionKey;
    if (pk == null) {
      throw PartitionKeyException('Missing partition key.');
    }
    TransactionalBatch? batch;
    final key = _opsByPk.keys.singleOrDefault((k) => k == pk);
    if (key == null) {
      batch = TransactionalBatch(container, continueOnError: true);
      _opsByPk[pk] = batch;
    } else {
      batch = _opsByPk[key]!;
    }
    batch.add(op);
    _ops.add(op);
  }

  @override

  /// Executes the [BatchOperation]s registered in this batch instance. Operations are grouped
  /// by partition keys and sent to Cosmos DB in chunks of 100 operations per partition key.
  Future<BatchResponse> execute({CosmosDbPermission? permission}) async {
    final resp = BatchResponse();
    final futures = <Future>[];
    var pending = 0;
    for (var batch in _opsByPk.values) {
      pending++;
      futures.add(
          batch.execute(permission: permission).whenComplete(() => pending--));
      while (pending > 2) {
        // throttle
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    await Future.wait(futures);
    resp.addAll(_ops.map((o) => o.result!));
    return resp;
  }

  @override
  List<dynamic> toJson() => _ops.map((o) => o.toJson()).toList();
}
