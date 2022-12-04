import 'dart:convert';

@Deprecated('Use CosmosDbPartition instead.')
typedef Partition = CosmosDbPartition;

/// Class representing a partition in a Cosmos DB collection.
class CosmosDbPartition {
  const CosmosDbPartition._(this.header);

  /// Creates a partition for a composite key.
  CosmosDbPartition.multi(Iterable<String> keys)
      : this._(MapEntry(
          'x-ms-documentdb-partitionkey',
          jsonEncode(keys),
        ));

  /// Creates a partition for a single key.
  CosmosDbPartition(String key) : this.multi([key]);

  /// Used for cross-partition queries.
  static const all = CosmosDbPartition._(MapEntry(
    'x-ms-documentdb-query-enablecrosspartition',
    'true',
  ));

  /// The HTTP header representing the target partition.
  final MapEntry<String, String> header;
}
