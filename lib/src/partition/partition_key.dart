import 'dart:convert';

import '../_internal/_http_header.dart';

/// Class representing a partition key.
class PartitionKey {
  const PartitionKey._(this.values);

  final List<dynamic> values;

  /// Partition key with a single property (`Hash`).
  PartitionKey(dynamic value) : this._(List.unmodifiable([value]));

  /// Creates a partition key for multiple keys (`MultiHash`).
  PartitionKey.hierarchical(List<dynamic> values)
      : this._(List.unmodifiable(values));

  /// Used for cross-partition queries.
  static const all = PartitionKey._([]);

  /// The HTTP header representing the target partition.
  Map<String, String> get header => (this == all)
      ? HttpHeader.enableCrossPartition
      : {HttpHeader.msDocumentDbPartitionKey: jsonEncode(values)};

  @override
  int get hashCode =>
      (values.length * 31) ^
      (values.isEmpty ? 0xFFFFFFFF : values.first.hashCode);

  @override
  bool operator ==(Object other) =>
      (other is PartitionKey) && _areListsEqual(values, other.values);

  static bool _areListsEqual(List a, List b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (!_areEqual(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }

  static bool _areEqual(dynamic a, dynamic b) {
    if (a is num && b is num) {
      return a.compareTo(b) == 0;
    } else if (a is String && b is String) {
      return a.compareTo(b) == 0;
    } else if (a is bool && b is bool) {
      return a == b;
    } else if (a is List && b is List) {
      return _areListsEqual(a, b);
    } else {
      return false;
    }
  }
}
