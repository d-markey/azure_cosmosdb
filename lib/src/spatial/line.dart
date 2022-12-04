import '../indexing/data_type.dart';
import 'point.dart';

/// Class representing a line.
class Line {
  Line();

  final _points = <Point>[];

  /// Collection of points making up the line.
  Iterable<Point> get points => _points.map((p) => p);

  /// Adds a point to the line.
  void add(Point point) => _points.add(point);

  /// Adds a set of points to the line.
  void addAll(Iterable<Point> points) => _points.addAll(points);

  // `true` iif the line contains no points.
  bool get isEmpty => points.isEmpty;

  // `true` iif the line contains one or more points.
  bool get isNotEmpty => points.isNotEmpty;

  // Returns a list where each entry represents a point's coordinates.
  List<List<double>> get coordinates =>
      points.map((p) => p.coordinates).toList();

  Map<String, dynamic> toJson() => {
        'type': DataType.lineString.name,
        'coordinates': coordinates,
      };
}
