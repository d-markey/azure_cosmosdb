import 'package:azure_cosmosdb/azure_cosmosdb.dart';

import '../base_document.dart';
import 'batch_operation.dart';
import 'batch_operation_create.dart';
import 'batch_operation_read.dart';
import 'batch_operation_upsert.dart';

class TransactionalBatch extends SpecialDocument {
  TransactionalBatch({this.isAtomic = true});

  final bool isAtomic;

  final _ops = <BatchOperation>[];

  void _add(BatchOperation op) {
    if (_ops.length >= 100) {
      throw Exception('Transactional batch is limited to 100 operations.');
    }
    _ops.add(op);
  }

  void create<T extends BaseDocument>(T item, {PartitionKeySpec? pk}) =>
      _add(BatchOperationCreate(item, pk: pk));

  void upsert<T extends BaseDocument>(T item, {PartitionKeySpec? pk}) =>
      _add(BatchOperationUpsert(item, pk: pk));

  void read(String id, {PartitionKey? partitionKey}) =>
      _add(BatchOperationRead(id, partitionKey: partitionKey));

  @override
  List<dynamic> toJson() => _ops.map((o) => o.toJson()).toList();
}
