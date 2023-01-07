import 'dart:convert';

import '../base_document.dart';

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

  static PartitionKeyRange fromJson(dynamic json) {
    final pkRange = PartitionKeyRange(
        json['id'], json['minInclusive'], json['maxExclusive']);
    pkRange.setEtag(json);
    return pkRange;
  }
}
