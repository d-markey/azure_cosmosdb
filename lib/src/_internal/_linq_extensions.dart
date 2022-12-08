class LinqException implements Exception {
  LinqException(this.message);

  final String message;
}

T _identity<T>(T item) => item;

extension Linq<T> on Iterable<T> {
  Iterable<T> asIterable() => map(_identity);

  Iterable<T> skipLast() {
    final keep = length - 1;
    return (keep > 0) ? take(keep) : const [];
  }

  T? firstOrDefault(bool Function(T) predicate) {
    if (isEmpty) return null;
    for (var item in this) {
      if (predicate(item)) return item;
    }
    return null;
  }

  T? singleOrDefault(bool Function(T) predicate) {
    if (isEmpty) return null;
    T? found;
    for (var item in this) {
      if (predicate(item)) {
        if (found != null) {
          throw LinqException(
              'Collection contains several items matching the predicate');
        }
        found = item;
      }
    }
    return found;
  }
}
