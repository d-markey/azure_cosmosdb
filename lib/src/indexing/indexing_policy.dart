import 'index_path.dart';
import 'indexing_enums.dart';
import 'spatial_index_path.dart';

class IndexingPolicy {
  IndexingPolicy(
      {this.indexingMode = IndexingMode.consistent, this.automatic = true});

  final String indexingMode;
  final bool automatic;
  final includedPaths = <IndexPath>[];
  final excludedPaths = <IndexPath>[];
  final compositeIndexes = <List<IndexPath>>[];
  final spatialIndexes = <SpatialIndexPath>[];

  Map<String, dynamic> toJson() => {
        'indexingMode': indexingMode,
        'automatic': automatic,
        'includedPaths': includedPaths.map((p) => p.toJson()).toList(),
        'excludedPaths': excludedPaths.map((p) => p.toJson()).toList(),
        if (compositeIndexes.isNotEmpty)
          'compositeIndexes': compositeIndexes
              .where((c) => c.isNotEmpty)
              .map((c) => c.map((p) => p.toJson()).toList())
              .toList(),
        if (spatialIndexes.isNotEmpty)
          'spatialIndexes': spatialIndexes.map((p) => p.toJson()).toList(),
      };
}
