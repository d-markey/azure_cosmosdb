import 'base_document.dart';
import 'paging.dart';
import 'partition.dart';

class Query extends Paging implements BaseDocument {
  Query(this.command, {Partition? partition, Map<String, dynamic>? params})
      : _partition = partition,
        super() {
    if (params != null) {
      _params.addAll(params);
    }
  }

  @override
  String get id => '';

  final String command;

  final Map<String, dynamic> _params = <String, dynamic>{};

  Partition? _partition;
  Partition get partition => _partition ?? Partition.all;

  void crossPartition() => _partition = Partition.all;

  void onPartition(String key) => _partition = Partition(key);

  void withParam(String name, dynamic value) => _params[name] = value;

  @override
  Map<String, dynamic> toJson() => {
        'query': command,
        'parameters': _params.entries
            .map((e) => {'name': e.key, 'value': e.value})
            .toList()
      };
}
