import '../_internal/_linq_extensions.dart';
import '../base_document.dart';
import '../client/http_status_codes.dart';

class BatchResponse<T extends BaseDocument> {
  final _results = <BatchOperationResult<T>>[];

  int get length => _results.length;

  T? operator [](int i) => _results[i].item;

  bool get success => _results.every((r) => r.success);

  Iterable<BatchOperationResult<T>> get results => _results.asIterable();

  Iterable<BatchOperationResult<T>> get errors =>
      _results.where((r) => !r.success);

  static BatchResponse<T> build<T extends BaseDocument>(
      List json, DocumentBuilder<T> builder) {
    final resp = BatchResponse<T>();
    for (var i = 0; i < json.length; i++) {
      final entry = json[i];
      final item = entry['resourceBody'];
      final doc = (item == null) ? null : builder(item);
      resp._results.add(BatchOperationResult(i, entry['statusCode'], doc));
    }
    return resp;
  }
}

class BatchOperationResult<T extends BaseDocument> {
  BatchOperationResult(this.index, this.statusCode, this.item);

  final int index;
  final int statusCode;
  final T? item;

  bool get success => HttpStatusCode.success(statusCode);
}
