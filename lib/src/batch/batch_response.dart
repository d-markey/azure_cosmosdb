import '../_internal/_linq_extensions.dart';
import '../base_document.dart';
import '../client/_context.dart';
import 'batch_operation.dart';
import 'batch_operation_result.dart';

/// Class containing the results of a batch operation.
class BatchResponse {
  final _results = <BatchOperationResult>[];

  /// The number of results in this batch response.
  int get length => _results.length;

  /// The item returned by Cosmos DB with this batch response.
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
extension BatchResponseInternalExt on BatchResponse {
  void addAll(Iterable<BatchOperationResult> results) =>
      _results.addAll(results);

  void add(BatchOperationResult result) => _results.add(result);

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
