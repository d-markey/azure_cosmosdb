import '../indexing/data_type.dart';
import 'line.dart';
import 'point.dart';

class Polygon extends Line {
  Polygon();

  /// List of points making up the polygon. The first point is automatically
  /// repeated at the end of the list.
  @override
  Iterable<Point> get points => super.points.followedBy(super.points.take(1));

  @override
  Map<String, dynamic> toJson() => {
        'type': DataType.polygon.name,
        'coordinates': coordinates,
      };
}
