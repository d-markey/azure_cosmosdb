import '../base_document.dart';
import '../indexing/partition.dart';
import 'paging.dart';

/// Class representing CosmosDB SQL query.
class Query extends Paging implements BaseDocument {
  /// Builds a new CosmosDB SQL query with [command] and [params].
  Query(this.command,
      {int? maxCount,
      CosmosDbPartition? partition,
      Map<String, dynamic>? params})
      : _partition = partition,
        _params = (params == null) ? null : Map<String, dynamic>.from(params),
        super(maxCount);

  @override
  String get id => '';

  /// The query's SQL [command].
  final String command;

  late final Map<String, dynamic>? _params;

  /// The partition where the query should be executed; by default, the query
  /// will be executed against all partitions.
  CosmosDbPartition get partition => _partition ?? CosmosDbPartition.all;
  CosmosDbPartition? _partition;

  /// Force the query to execute in all partitions.
  void crossPartition() => _partition = CosmosDbPartition.all;

  /// Restrict the query to the partition identified by [key].
  void onPartition(String key) => _partition = CosmosDbPartition(key);

  /// Registers a paramater/value to the query.
  void withParam(String name, dynamic value) =>
      (_params ??= <String, dynamic>{})[name] = value;

  @override
  Map<String, dynamic> toJson() => {
        'query': command,
        if (_params != null)
          'parameters': _params!.entries
              .map((e) => {'name': e.key, 'value': e.value})
              .toList()
      };
}
