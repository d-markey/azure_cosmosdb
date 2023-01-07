import 'dart:convert';

import '../base_document.dart';
import '../partition/partition_key.dart';
import '../partition/partition_key_spec.dart';
import 'batch_operation.dart';

class BatchOperationDelete extends BatchOperation {
  BatchOperationDelete(this.id,
      {PartitionKeySpec? partitionKeySpec, PartitionKey? partitionKey})
      : super(partitionKey: partitionKey, partitionKeySpec: partitionKeySpec);

  @override
  final BatchOperationType op = BatchOperationType.delete;

  final String id;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'id': id,
      'partitionKey': jsonEncode(
          (partitionKey ?? partitionKeySpec?.from(DocumentWithId(id)))?.values),
    });
}
