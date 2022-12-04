import '../indexing/data_type.dart';
import 'polygon.dart';

/// Class representing a list of polygons.
class MultiPolygon {
  MultiPolygon();

  /// The list of polygons
  final polygons = <Polygon>[];

  bool get isEmpty => polygons.isEmpty;

  bool get isNotEmpty => polygons.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'type': DataType.multiPolygon.name,
        'coordinates': polygons.map((p) => p.coordinates).toList(),
      };
}
