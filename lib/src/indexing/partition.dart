import 'dart:convert';

import 'package:azure_cosmosdb/src/_internal/_http_header.dart';

@Deprecated('Use CosmosDbPartition instead.')
typedef Partition = CosmosDbPartition;

/// Class representing a partition in a Cosmos DB collection.
class CosmosDbPartition {
  const CosmosDbPartition._(this.header);

  /// Creates a partition for a single key.
  CosmosDbPartition(String key)
      : this._({
          HttpHeader.msDocumentDbPartitionKey: jsonEncode([key])
        });

  /// Used for cross-partition queries.
  static const all = CosmosDbPartition._(HttpHeader.enableCrossPartition);

  /// The HTTP header representing the target partition.
  final Map<String, String> header;
}
