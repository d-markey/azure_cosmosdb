import 'dart:convert';

import '../base_document.dart';
import '../partition/partition_key.dart';
import '../partition/partition_key_spec.dart';

class BatchOperationType {
  const BatchOperationType._(this.name);

  final String name;

  static const create = BatchOperationType._('Create');
  static const upsert = BatchOperationType._('Upsert');
  static const read = BatchOperationType._('Read');
  static const delete = BatchOperationType._('Delete');
  static const replace = BatchOperationType._('Replace');
  static const patch = BatchOperationType._('Patch');
}

abstract class BatchOperation {
  BatchOperation({PartitionKeySpec? partitionKeySpec, this.partitionKey})
      : partitionKeySpec = partitionKeySpec ?? PartitionKeySpec.id;

  final PartitionKey? partitionKey;
  final PartitionKeySpec? partitionKeySpec;

  PartitionKey? getPartitionKey() => partitionKey;

  BatchOperationType get op;

  Map<String, dynamic> toJson() => {'operationType': op.name};
}

abstract class BatchOperationOnItem<T extends BaseDocument>
    extends BatchOperation {
  BatchOperationOnItem(this.item,
      {PartitionKeySpec? partitionKeySpec, PartitionKey? partitionKey})
      : super(partitionKey: partitionKey, partitionKeySpec: partitionKeySpec);

  final T item;

  @override
  PartitionKey? getPartitionKey() =>
      super.getPartitionKey() ?? partitionKeySpec?.from(item);

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'id': item.id,
      'partitionKey': jsonEncode(
          (partitionKey ?? (partitionKeySpec ?? PartitionKeySpec.id).from(item))
              ?.values),
      'resourceBody': item.toJson(),
    });
}
