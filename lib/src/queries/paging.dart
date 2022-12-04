/// Class used for pagination.
class Paging {
  Paging(int? maxCount) : maxCount = maxCount ?? -1;

  /// Maximum items per page.
  final int maxCount;

  /// Continuation token provided by CosmosDB.
  String get continuation => _continuation;
  String _continuation = '';
}

// internal use
extension ContinuationExt on Paging {
  void setContinuation(String value) => _continuation = value;
}
