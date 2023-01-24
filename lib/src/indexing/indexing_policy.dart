import 'index_path.dart';
import 'indexing_mode.dart';
import 'spatial_index_path.dart';

/// Class representing a container's indexing policy.
class IndexingPolicy {
  IndexingPolicy(
      {this.indexingMode = IndexingMode.consistent, this.automatic = true});

  /// Indexing mode. See constants available in [IndexingMode].
  final IndexingMode indexingMode;

  /// Automatic indexing.
  final bool automatic;

  /// JSON paths to fields that must be indexed. Must end with `/?` for scalar
  /// fields, or `/*` to include all sub-nodes.
  final includedPaths = <IndexPath>[];

  /// JSON paths to fields that must not be indexed. See also [includedPaths].
  final excludedPaths = <IndexPath>[];

  /// List of JSON paths for composite indexes. Only scalar values are covered,
  /// so these paths should not include the `/?` nor the `/*`suffix.
  final compositeIndexes = <List<IndexPath>>[];

  /// List of JSON paths for spatial indexing.
  final spatialIndexes = <SpatialIndexPath>[];

  /// Serializes this instance to a JSON object.
  Map<String, dynamic> toJson() => {
        'indexingMode': indexingMode.name,
        'automatic': automatic,
        if (includedPaths.isNotEmpty)
          'includedPaths': includedPaths.map((p) => p.toJson()).toList(),
        if (excludedPaths.isNotEmpty)
          'excludedPaths':
              excludedPaths.map((p) => p.toJson()..remove('order')).toList(),
        if (compositeIndexes.isNotEmpty)
          'compositeIndexes': compositeIndexes
              .where((c) => c.isNotEmpty)
              .map((c) => c.map((p) => p.toJson()).toList())
              .toList(),
        if (spatialIndexes.isNotEmpty)
          'spatialIndexes': spatialIndexes.map((p) => p.toJson()).toList(),
      };

  /// Deserializes data from JSON object [json] into a new [IndexingPolicy] instance.
  /// Handles fields `indexingMode`, `includedPaths`, `excludedPaths`, `spatialIndexes`,
  /// `compositeIndexes`.
  static IndexingPolicy fromJson(Map json) {
    final mode = IndexingMode.tryParse(json['indexingMode']);
    final automatic = json['automatic'] as bool;
    final policy = IndexingPolicy(indexingMode: mode!, automatic: automatic);
    var item = json['includedPaths'];
    if (item != null) {
      for (Map include in item) {
        policy.includedPaths.add(IndexPath.fromJson(include));
      }
    }
    item = json['excludedPaths'];
    if (item != null) {
      for (Map exclude in item) {
        policy.excludedPaths.add(IndexPath.fromJson(exclude));
      }
    }
    item = json['spatialIndexes'];
    if (item != null) {
      for (Map spatial in item) {
        policy.spatialIndexes.add(SpatialIndexPath.fromJson(spatial));
      }
    }
    item = json['compositeIndexes'];
    if (item != null) {
      for (List composite in item) {
        try {
          policy.compositeIndexes
              .add(composite.map((i) => IndexPath.fromJson(i)).toList());
        } catch (ex, st) {
          print(ex);
          print(st);
          rethrow;
        }
      }
    }
    return policy;
  }
}
