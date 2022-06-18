import 'dart:convert';

class Partition {
  Partition._(this.header);

  Partition(String key)
      : this._(MapEntry(
          'x-ms-documentdb-partitionkey',
          jsonEncode([key]),
        ));

  static final all = Partition._(MapEntry(
    'x-ms-documentdb-query-enablecrosspartition',
    'true',
  ));

  final MapEntry<String, String> header;
}
