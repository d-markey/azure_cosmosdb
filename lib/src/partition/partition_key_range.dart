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
  JSonMessage toJson() => const {};

  /// Returns `true` is this partition key range contains the specified [hash].
  bool contains(PartitionKeyHashV2 hash) =>
      minInclusive.compareTo(hash.hex) <= 0 &&
      0 < maxExclusive.compareTo(hash.hex);

  /// Deserializes data from JSON object [json] into a new [PartitionKeyRange] instance.
  /// Handles fields `id`, `minInclusive`, `maxExclusive`.
  static PartitionKeyRange fromJson(dynamic json) {
    final pkRange = PartitionKeyRange(
        json['id'], json['minInclusive'], json['maxExclusive']);
    pkRange.setEtag(json);
    return pkRange;
  }
}

/// Extension on [Iterable] of [PartitionKeyRange].
extension PartitionKeyRangeExt on Iterable<PartitionKeyRange> {
  /// Returns the [PartitionKeyRange] for the specified [partitionKey], or `null` if
  /// no match is found.
  PartitionKeyRange? findRangeFor(PartitionKey partitionKey) {
    final hash = PartitionKeyHashV2.hierarchical(partitionKey.values);
    return cast<PartitionKeyRange?>()
        .singleWhere((r) => r!.contains(hash), orElse: () => null);
  }
}
