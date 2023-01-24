import 'dart:convert';

import 'package:meta/meta.dart';

import '../base_document.dart';
import '../client/_context.dart';
import '../partition/partition_key.dart';
import '../partition/partition_key_spec.dart';
import 'batch.dart';
import 'batch_operation_result.dart';
import 'batch_operation_type.dart';
import 'operations/batch_operation_create.dart';
import 'operations/batch_operation_read.dart';

/// Base class for batch operations.
abstract class BatchOperation {
  /// Creates a new batch operation targeting [partitionKey].
  BatchOperation({PartitionKey? partitionKey}) : _partitionKey = partitionKey;

  final PartitionKey? _partitionKey;

  /// The operation's target [partitionKey].
  PartitionKey? get partitionKey => _partitionKey;

  /// The operation's type.
  BatchOperationType get type;

  /// Serializes this instance to a JSON object.
  Map<String, dynamic> toJson() => {
        'operationType': type.name,
        'partitionKey': jsonEncode(partitionKey?.values),
      };

  BatchOperationResult? _result;

  /// The operation's result. This property will be set after calling [Batch.execute]; it
  /// returns `null` if the batch has not been executed yet.
  BatchOperationResult? get result => _result;

  BatchOperationResult _setResult(Map res, Context? context) {
    final statusCode = res['statusCode'];
    final retryAfterMs = res['retryAfterMilliseconds'];
    final result = BatchOperationResult.noItem(this, statusCode, retryAfterMs);
    _result = result;
    return result;
  }
}

/// Base class for batch operations on specific document types, e.g. [BatchOperationRead].
abstract class BatchOperationOnType<T extends BaseDocument>
    extends BatchOperation {
  BatchOperationOnType({PartitionKey? partitionKey})
      : super(partitionKey: partitionKey);

  @override
  BatchOperationResult<T>? get result => _result as BatchOperationResult<T>?;

  @override
  BatchOperationResult<T> _setResult(Map res, Context? context) {
    final statusCode = res['statusCode'];
    final retryAfterMs = res['retryAfterMilliseconds'];
    final json = res['resourceBody'];
    T? doc;
    if (json != null) {
      final builder = context!.getBuilder<T>();
      doc = builder(json);
    }
    final result = BatchOperationResult<T>(this, statusCode, retryAfterMs, doc);
    _result = result;
    return result;
  }
}

/// Base class for batch operations on specific items, e.g. [BatchOperationCreate].
abstract class BatchOperationOnItem<T extends BaseDocument>
    extends BatchOperationOnType<T> {
  BatchOperationOnItem(this.item,
      {PartitionKeySpec? partitionKeySpec, PartitionKey? partitionKey})
      : _partitionKeySpec = partitionKeySpec,
        super(partitionKey: partitionKey);

  /// The operation's target [item].
  final T item;

  final PartitionKeySpec? _partitionKeySpec;

  @override
  PartitionKey? get partitionKey =>
      super.partitionKey ?? _partitionKeySpec?.from(item);

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'id': item.id,
      'resourceBody': item.toJson(),
    });
}

// internal use
@internal
extension BatchOperationInternalExt on BatchOperation {
  BatchOperationResult setResult(Map res, Context? context) =>
      _setResult(res, context);

  void clearResult() => _result = null;
}
