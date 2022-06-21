import 'base_document.dart';
import 'paging.dart';
import 'partition.dart';

/// Class representing CosmosDB SQL query.
class Query extends Paging implements BaseDocument {
  /// Builds a new CosmosDB SQL query with [command] and [params].
  Query(this.command, {Partition? partition, Map<String, dynamic>? params})
      : _partition = partition,
        super() {
    if (params != null) {
      _params.addAll(params);
    }
  }

  @override
  String get id => '';

  /// The query's SQL [command].
  final String command;

  final Map<String, dynamic> _params = <String, dynamic>{};

  /// The partition where the query should be executed; by default, the query will be
  /// executed against all partitions.
  Partition get partition => _partition ?? Partition.all;
  Partition? _partition;

  /// Force the query to execute in all partitions.
  void crossPartition() => _partition = Partition.all;

  /// Restrict the query to the partition identified by [key].
  void onPartition(String key) => _partition = Partition(key);

  /// Registers a paramater/value to the query.
  void withParam(String name, dynamic value) => _params[name] = value;

  @override
  Map<String, dynamic> toJson() => {
        'query': command,
        'parameters': _params.entries
            .map((e) => {'name': e.key, 'value': e.value})
            .toList()
      };
}
