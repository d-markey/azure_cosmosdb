import '../base_document.dart';
import '../client/http_status_codes.dart';
import 'batch_operation.dart';

class BatchOperationResult<T extends BaseDocument> {
  BatchOperationResult(this.operation, this.statusCode, this.item);

  BatchOperationResult.withoutItem(this.operation, this.statusCode)
      : item = null;

  final BatchOperation operation;
  final int statusCode;
  final T? item;

  bool get isSuccess => HttpStatusCode.isSuccess(statusCode);
}
