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

  Map<String, dynamic> toJson() => {
        'path': path,
        'types': (types ?? DataType.spatialTypes).map((t) => t.name).toList(),
        if (boundingBox != null) 'boundingBox': boundingBox!.toJson(),
      };
}
