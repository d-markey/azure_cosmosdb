import '../base_document.dart';
import '../partition/partition_key.dart';
import 'paging.dart';

/// Class representing CosmosDB SQL query.
class Query extends Paging implements SpecialDocument {
  /// Builds a new CosmosDB SQL query with [command] and [params].
  Query(this.command,
      {int? maxCount, PartitionKey? partitionKey, JSonMessage? params})
      : _partitionKey = partitionKey,
        _params = (params == null) ? null : {...params},
        super(maxCount);

  /// The query's SQL [command].
  final String command;

  late final JSonMessage? _params;

  /// The partition where the query should be executed; by default, the query
  /// will be executed against all partitions.
  PartitionKey get partitionKey => _partitionKey ?? PartitionKey.all;
  PartitionKey? _partitionKey;

  /// Force the query to execute in all partitions.
  void crossPartition() => _partitionKey = null;

  /// Restrict the query to the partition identified by [partitionKey].
  void onPartition(PartitionKey partitionKey) => _partitionKey = partitionKey;

  /// Registers a paramater/value to the query.
  void withParam(String name, dynamic value) =>
      (_params ??= <String, dynamic>{})[name] = value;

  @override
  JSonMessage toJson() => {
        'query': command,
        if (_params != null)
          'parameters': _params!.entries
              .map((e) => {'name': e.key, 'value': e.value})
              .toList()
      };
}
