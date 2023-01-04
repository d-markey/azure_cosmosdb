import 'dart:convert';

import 'package:azure_cosmosdb/azure_cosmosdb.dart';

/// Class representing a partition key range.
class PartitionKeyRange extends BaseDocumentWithEtag {
  PartitionKeyRange(this.id, this.minInclusive, this.maxExclusive);

  @override
  final String id;

  final String minInclusive;
  final String maxExclusive;

  @override
  dynamic toJson() =>
      {'id': id, 'minInclusive': minInclusive, 'maxExclusive': maxExclusive};

  @override
  String toString() => jsonEncode(toJson());

  static PartitionKeyRange fromJson(dynamic body) {
    final pkRange = PartitionKeyRange(
        body['id'], body['minInclusive'], body['maxExclusive']);
    pkRange.setEtag(body);
    return pkRange;
  }
}
