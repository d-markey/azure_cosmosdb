import 'bounding_box.dart';
import 'data_type.dart';

/// Class representing a spatial index.
class SpatialIndexPath {
  SpatialIndexPath(this.path, {Iterable<DataType>? types, this.boundingBox})
      : types = (types == null) ? null : List<DataType>.unmodifiable(types);

  /// JSON path to the field.
  final String path;

  /// Data types covered by the index.
  final List<DataType>? types;

  /// Bounding box (geometry only).
  final BoundingBox? boundingBox;

  /// Serializes this instance to a JSON object.
  Map<String, dynamic> toJson() => {
        'path': path,
        'types': (types ?? DataType.spatial).map((t) => t.name).toList(),
        if (boundingBox != null) 'boundingBox': boundingBox!.toJson(),
      };

  /// Deserializes data from JSON object [json] into a new [SpatialIndexPath] instance.
  /// Handles fields `path`, `types`, `boundingBox`.
  static SpatialIndexPath fromJson(Map json) {
    final path = json['path'];
    final types = json['types'] as List?;
    final bbox = json['boundingBox'];
    return SpatialIndexPath(
      path,
      types: (types == null) ? null : types.map((t) => DataType.tryParse(t)!),
      boundingBox: (bbox == null) ? null : BoundingBox.fromJson(bbox),
    );
  }
}
