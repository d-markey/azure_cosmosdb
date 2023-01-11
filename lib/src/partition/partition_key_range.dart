import '../base_document.dart';
import '_partition_key_hash_v2.dart';
import 'partition_key.dart';

/// Class representing a partition key range.
class PartitionKeyRange extends BaseDocumentWithEtag {
  PartitionKeyRange(this.id, this.minInclusive, this.maxExclusive);

  @override
  final String id;

  final String minInclusive;
  final String maxExclusive;

  @override
  dynamic toJson() => null;

  bool contains(PartitionKeyHashV2 hash) =>
      minInclusive.compareTo(hash.hex) <= 0 &&
      0 < maxExclusive.compareTo(hash.hex);

  static PartitionKeyRange fromJson(dynamic json) {
    final pkRange = PartitionKeyRange(
        json['id'], json['minInclusive'], json['maxExclusive']);
    pkRange.setEtag(json);
    return pkRange;
  }
}

extension PartitionKeyRangeExt on Iterable<PartitionKeyRange> {
  PartitionKeyRange? findFor(PartitionKey pk) {
    final hash = PartitionKeyHashV2.multi(pk.values);
    return cast<PartitionKeyRange?>()
        .singleWhere((r) => r!.contains(hash), orElse: () => null);
  }
}
