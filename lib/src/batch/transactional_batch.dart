import 'package:meta/meta.dart';

import '../_internal/_http_header.dart';
import '../_internal/_linq_extensions.dart';
import '../client/http_status_codes.dart';
import '../cosmos_db_container.dart';
import '../cosmos_db_exceptions.dart';
import '../partition/partition_key.dart';
import '../partition/partition_key_range.dart';
import '../partition/partition_key_spec.dart';
import '../permissions/cosmos_db_permission.dart';
import 'batch.dart';
import 'batch_operation.dart';
import 'batch_response.dart';

/// Class representing a transactional batch. This implementation provides atomic and
/// non-atomic transactions. Atomic transactions will always fail on error, and support
/// a maximum of 100 operations per batch. For non-atomic transactions, the behavior in
/// case of error can be controlled via the [continueOnError] flag.
/// Non-atomic transactions send operations in chunks of 100, effectively working around
/// the Cosmos DB limitation of 100 operations per batch.
class TransactionalBatch extends Batch {
  TransactionalBatch._(CosmosDbContainer container,
      {PartitionKey? partitionKey,
      required this.isAtomic,
      bool continueOnError = true})
      : _continueOnError = continueOnError,
        super(container, partitionKey);

  /// Creates an atomic [Batch] instance operating on [container] and [partitionKey].
  /// The partition key is optional, provided each operation in this batch instance
  /// can provide a partition key. Operations working on a document should be able to
  /// extract the document's partition key using the [container]'s [PartitionKeySpec].
  /// For atomic batches, the [continueOnError] flag is always `false`.
  TransactionalBatch.atomic(CosmosDbContainer container,
      {PartitionKey? partitionKey})
      : this._(container, partitionKey: partitionKey, isAtomic: true);

  /// Creates a non-atomic [Batch] instance operating on [container] and [partitionKey].
  /// The partition key is optional, provided each operation in this batch instance
  /// can provide a partition key. Operations working on a document should be able to
  /// extract the document's partition key using the [container]'s [PartitionKeySpec].
  /// By default, [continueOnError] is `true` and all operations will be executed and
  /// report their status. If [continueOnError] is `false`, the batch process will
  /// stop upon the first failing operation. In this case, that operation will report
  /// a specific error status while all subsequent operations will fail with a
  /// [HttpStatusCode.failedDependency] error status.
  TransactionalBatch(CosmosDbContainer container,
      {PartitionKey? partitionKey, bool continueOnError = true})
      : this._(container,
            partitionKey: partitionKey,
            isAtomic: false,
            continueOnError: continueOnError);

  /// Returns the HTTP headers for this batch request (retrieves the partition key
  /// range ID and maps properties [isAtomic] and [continueOnError]).
  Map<String, String> getHeaders(Iterable<PartitionKeyRange> pkRanges) {
    var pk = _ops
        .map((op) => op.partitionKey)
        .followedBy([partitionKey])
        .whereNotNull()
        .distinct();
    if (pk.isEmpty) {
      throw PartitionKeyException('Missing partition key.');
    } else if (pk.length > 1) {
      throw PartitionKeyException(
          'Partition keys map to several partition key ranges.');
    }
    final pkr = pkRanges.findRangeFor(pk.single);
    return {
      HttpHeader.msCosmosIsBatchRequest: 'true',
      HttpHeader.msCosmosBatchAtomic: isAtomic ? 'true' : 'false',
      HttpHeader.msCosmosBatchContinueOnError:
          continueOnError ? 'true' : 'false',
      HttpHeader.msDocumentDbPartitionKeyRangeId: pkr!.id,
    };
  }

  final bool _continueOnError;

  @override
  bool get continueOnError => _continueOnError && !isAtomic;

  @override
  final bool isAtomic;

  @override
  final bool isCrossPartition = false;

  @override
  int get length => _ops.length;

  @override
  Iterable<BatchOperation> get operations => _ops.asIterable();

  final _ops = <BatchOperation>[];

  @override
  void recycle() => _ops.clear();

  @override
  void add(BatchOperation op) {
    if (_ops.length >= 100 && isAtomic) {
      throw ApplicationException(
          'Transactional batch is limited to 100 operations.');
    }
    _ops.add(op);
  }

  @override
  Future<BatchResponse> execute({CosmosDbPermission? permission}) async {
    if (_ops.length <= 100) {
      return await container.execute(this, permission: permission);
    } else {
      final resp = BatchResponse();
      final batch = clone();
      var index = 0;
      while (index < _ops.length) {
        batch._ops.clear();
        batch._ops.addAll(_ops.skip(index).take(100));
        index += 100;
        final r = await batch.execute(permission: permission);
        resp.addAll(r.results);
        if (!continueOnError && !r.isSuccess) {
          final err = {'statusCode': HttpStatusCode.failedDependency};
          for (var i = index; i < _ops.length; i++) {
            resp.add(_ops[i].setResult(err, null));
          }
          break;
        }
      }
      return resp;
    }
  }

  @override
  List<dynamic> toJson() => _ops.map((o) => o.toJson()).toList();
}

// internal use
@internal
extension BatchInternalExt on TransactionalBatch {
  TransactionalBatch clone() => TransactionalBatch._(container,
      isAtomic: isAtomic, continueOnError: continueOnError);
}
