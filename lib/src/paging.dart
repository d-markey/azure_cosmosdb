class Paging {
  Paging([int? maxCount]) : maxCount = maxCount ?? -1;

  int maxCount;

  String _continuation = '';
  String get continuation => _continuation;
}

// internal use
extension ContinuationExt on Paging {
  void setContinuation(String? value) {
    if (value != null && value.isNotEmpty) {
      _continuation = value;
    }
  }
}
