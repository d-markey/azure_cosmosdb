import 'package:meta/meta.dart';

import '../_internal/_extensions.dart';
import '../base_document.dart';
import '../client/_context.dart';
import 'batch_operation.dart';
import 'batch_operation_result.dart';

/// Class containing the results of a batch transaction.
class BatchResponse {
  final _results = <BatchOperationResult>[];

  /// The number of results in this batch response.
  int get length => _results.length;

  /// Provides access to items returned by Cosmos DB in this batch response.
  T? get<T extends BaseDocument>(int index) => _results[index].item as T?;

  /// Returns `true` if all batch operations succeeded, or if the result list is empty.
  bool get isSuccess => _results.isEmpty || _results.every((r) => r.isSuccess);

  /// Returns all results contained in this batch response.
  Iterable<BatchOperationResult> get results => _results.asIterable();

  /// Returns only the results that have failed.
  Iterable<BatchOperationResult> get errors =>
      _results.where((r) => !r.isSuccess);
}

// internal use
@internal
extension BatchResponseInternalExt on BatchResponse {
  void addAll(Iterable<BatchOperationResult> results) =>
      _results.addAll(results);

  void add(BatchOperationResult result) => _results.add(result);

  void update(BatchResponse newResults) {
    final updated = Map<BatchOperation, BatchOperationResult>.fromEntries(
        newResults._results.map((r) => MapEntry(r.operation, r)));
    for (var i = 0; i < _results.length; i++) {
      final r = updated[_results[i].operation];
      if (r != null) {
        _results[i] = r;
      }
    }
  }

  static BatchResponse build(
      List json, Iterable<BatchOperation> operations, Context context) {
    final resp = BatchResponse();
    var index = 0;
    for (var op in operations) {
      resp._results.add(op.setResult(json[index], context));
      index += 1;
    }
    return resp;
  }
}
