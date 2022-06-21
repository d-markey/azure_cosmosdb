extension Linq<T> on Iterable<T> {
  T? firstOrDefault([bool Function(T)? predicate]) {
    if (isEmpty) return null;
    if (predicate == null) return first;
    for (var item in this) {
      if (predicate(item)) return item;
    }
    return null;
  }

  T? singleOrDefault([bool Function(T)? predicate]) {
    if (isEmpty) return null;
    if (predicate == null) {
      if (length == 1) return first;
      throw Exception('Collection has more than one item');
    }
    T? found;
    for (var item in this) {
      if (predicate(item)) {
        if (found != null) {
          throw Exception(
              'Collection contains several items matching the predicate');
        }
        found = item;
      }
    }
    return found;
  }
}
