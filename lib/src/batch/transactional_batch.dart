import '../_internal/_http_header.dart';
import '../_internal/_linq_extensions.dart';
import '../base_document.dart';
import '../cosmos_db_container.dart';
import '../partition/partition_key.dart';
import '../permissions/cosmos_db_permission.dart';
import 'batch_operation.dart';
import 'batch_operation_create.dart';
import 'batch_operation_delete.dart';
import 'batch_operation_read.dart';
import 'batch_operation_upsert.dart';
import 'batch_response.dart';

class TransactionalBatch<T extends BaseDocument> extends SpecialDocument {
  TransactionalBatch.atomic(this.container)
      : isAtomic = true,
        continueOnError = false;

  TransactionalBatch(this.container, {this.continueOnError = true})
      : isAtomic = false;

  final CosmosDbContainer container;

  Map<String, String> get headers => {
        HttpHeader.msCosmosIsBatchRequest: 'true',
        HttpHeader.msCosmosBatchAtomic: isAtomic ? 'true' : 'false',
        HttpHeader.msCosmosBatchContinueOnError:
            continueOnError ? 'true' : 'false',
        HttpHeader.msDocumentDbPartitionKeyRangeId: '0',
      };

  final bool isAtomic;
  final bool continueOnError;

  final _ops = <BatchOperation>[];

  Iterable<BatchOperation> get operations => _ops.asIterable();

  void _add(BatchOperation op) {
    if (_ops.length >= 100) {
      throw Exception('Transactional batch is limited to 100 operations.');
    }
    _ops.add(op);
  }

  void create(T item, {PartitionKey? partitionKey}) =>
      _add(BatchOperationCreate(item,
          partitionKeySpec: container.partitionKeySpec,
          partitionKey: partitionKey));

  void upsert(T item, {PartitionKey? partitionKey}) =>
      _add(BatchOperationUpsert(item,
          partitionKeySpec: container.partitionKeySpec,
          partitionKey: partitionKey));

  void read(String id, {PartitionKey? partitionKey}) =>
      _add(BatchOperationRead(id,
          partitionKeySpec: container.partitionKeySpec,
          partitionKey: partitionKey));

  void delete(String id, {PartitionKey? partitionKey}) =>
      _add(BatchOperationDelete(id,
          partitionKeySpec: container.partitionKeySpec,
          partitionKey: partitionKey));

  Future<BatchResponse<T>> execute({CosmosDbPermission? permission}) =>
      container.execute<T>(this, permission: permission);

  @override
  List<dynamic> toJson() => _ops.map((o) => o.toJson()).toList();
}
