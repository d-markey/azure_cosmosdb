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
}
