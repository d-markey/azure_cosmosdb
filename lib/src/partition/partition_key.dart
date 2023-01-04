import 'dart:convert';

import '../_internal/_http_header.dart';

/// Class representing a partition key.
class PartitionKey {
  const PartitionKey._(this.values);

  final List<dynamic> values;

  /// Partition key with a single property.
  PartitionKey(String value) : this._(List.unmodifiable([value]));

  /// Creates a partition key for multiple keys.
  PartitionKey.multi(List<dynamic> values) : this._(List.unmodifiable(values));

  /// Used for cross-partition queries.
  static const all = PartitionKey._([]);

  /// The HTTP header representing the target partition.
  Map<String, String> get header => (this == all)
      ? HttpHeader.enableCrossPartition
      : {HttpHeader.msDocumentDbPartitionKey: jsonEncode(values)};
}
