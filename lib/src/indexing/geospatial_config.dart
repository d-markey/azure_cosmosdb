import 'indexing_policy.dart';

/// Constants for geo spatial config.
class GeospatialConfig {
  const GeospatialConfig._(this.name);

  /// The [name] of this instance.
  final String name;

  /// Geometry type.
  static const geometry = GeospatialConfig._('Geometry');

  /// Geography type.
  static const geography = GeospatialConfig._('Geography');

  /// Find proper geospatial config for the [indexingPolicy] if provided. `null`
  /// if [indexingPolicy] or [IndexingPolicy.spatialIndexes] is `null`.
  static GeospatialConfig? forPolicy(IndexingPolicy? indexingPolicy) {
    final spatialIndexes = indexingPolicy?.spatialIndexes;
    if (spatialIndexes == null) return null;
    if (spatialIndexes.any((index) => index.boundingBox != null)) {
      return GeospatialConfig.geometry;
    } else {
      return GeospatialConfig.geography;
    }
  }

  /// Serializes this instance to a JSON object.
  Map<String, dynamic> toJson() => {'type': name};
}
