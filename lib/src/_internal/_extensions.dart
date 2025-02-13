String buildUrl(String baseUrl, String segment1,
    [String? segment2, String? segment3, String? segment4, String? segment5]) {
  baseUrl = baseUrl.trim();
  if (baseUrl.isNotEmpty && !baseUrl.endsWith('/')) {
    baseUrl += '/';
  }
  final path = [segment1, segment2, segment3, segment4, segment5]
      .whereNotNull()
      .map(Uri.encodeComponent)
      .join('/');
  return baseUrl.isEmpty ? path : '$baseUrl$path';
}

class LinqException implements Exception {
  LinqException(this.message);

  final String message;
}

T _identity<T>(T item) => item;
bool _notNull(dynamic item) => item != null;

extension LinqExt<T> on Iterable<T> {
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
          throw LinqException('Several items match the predicate.');
        }
        found = item;
      }
    }
    return found;
  }

  Iterable<T> distinct() sync* {
    final seen = <T>{};
    for (var item in this) {
      if (seen.add(item)) {
        yield item;
      }
    }
  }
}

extension NullableLinqExt<T> on Iterable<T?> {
  Iterable<T> whereNotNull() => where(_notNull).cast<T>();
}
