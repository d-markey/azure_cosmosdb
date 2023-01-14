import '../_internal/_http_header.dart';
import '../_internal/_linq_extensions.dart';
import '../client/http_status_codes.dart';
import '../cosmos_db_container.dart';
import '../cosmos_db_exceptions.dart';
import '../partition/partition_key_range.dart';
import '../permissions/cosmos_db_permission.dart';
import 'batch.dart';
import 'batch_operation.dart';
import 'batch_response.dart';

class TransactionalBatch extends Batch {
  TransactionalBatch._(this.container,
      {required this.isAtomic, required this.continueOnError});

  TransactionalBatch.atomic(CosmosDbContainer container)
      : this._(container, isAtomic: true, continueOnError: false);

  TransactionalBatch(CosmosDbContainer container, {bool continueOnError = true})
      : this._(container, isAtomic: false, continueOnError: continueOnError);

  @override
  final CosmosDbContainer container;

  /// Returns the HTTP headers for this batch request (retrieves the partition key
  /// range ID and maps properties [isAtomic] and [continueOnError]).
  Map<String, String> getHeaders(Iterable<PartitionKeyRange> pkRanges) {
    final pk = _ops.map((op) => op.partitionKey).whereNotNull().distinct();
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

  @override
  final bool continueOnError;

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
      final batch = _clone();
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

  TransactionalBatch _clone() => TransactionalBatch._(container,
      isAtomic: isAtomic, continueOnError: continueOnError);

  @override
  List<dynamic> toJson() => _ops.map((o) => o.toJson()).toList();
}
