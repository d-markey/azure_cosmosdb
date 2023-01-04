import 'dart:convert';

import '../partition/partition_key.dart';
import 'batch_operation.dart';

class BatchOperationRead extends BatchOperation {
  BatchOperationRead(this.id, {this.partitionKey});

  @override
  final BatchOperationType op = BatchOperationType.read;

  final String id;
  final PartitionKey? partitionKey;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'id': id,
      'partitionKey': jsonEncode(partitionKey?.values ?? [id]),
    });
}
