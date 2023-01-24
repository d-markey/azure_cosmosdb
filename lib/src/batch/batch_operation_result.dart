import '../base_document.dart';
import '../client/http_status_codes.dart';
import 'batch_operation.dart';
import 'operations/batch_operation_delete.dart';

/// Class representing a [BatchOperation]'s result.
class BatchOperationResult<T extends BaseDocument> {
  BatchOperationResult(
      this.operation, this.statusCode, this.retryAfterMs, this.item);

  BatchOperationResult.noItem(
      this.operation, this.statusCode, this.retryAfterMs)
      : item = null;

  /// The [BatchOperation] associated to this result.
  final BatchOperation operation;

  /// The [BatchOperation]'s status code; see constants in [HttpStatusCode].
  final int statusCode;

  /// When [statusCode] is [HttpStatusCode.tooManyRequests], contains the value in the
  /// `retryAfterMilliseconds` field returned by Cosmos DB.
  final int? retryAfterMs;

  /// The document resulting from the [BatchOperation], if applicable. For
  /// [BatchOperationDelete], it is always `null`.
  final T? item;

  /// `true` if the operation succeeded, `false` otherwise.
  bool get isSuccess => HttpStatusCode.isSuccess(statusCode);
}
