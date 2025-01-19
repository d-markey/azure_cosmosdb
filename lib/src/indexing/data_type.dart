import '../_internal/_extensions.dart';

/// Constants for data types.
class DataType {
  const DataType._(this.name);

  /// The [name] of this instance.
  final String name;

  /// String type.
  static const string = DataType._('String');

  /// Numeric type.
  static const number = DataType._('Number');

  /// Point type.
  static const point = DataType._('Point');

  /// Polygon type.
  static const polygon = DataType._('Polygon');

  /// Multi-polygon type.
  static const multiPolygon = DataType._('MultiPolygon');

  /// Line-string type.
  static const lineString = DataType._('LineString');

  /// List of spatial data types.
  static const spatial = [point, polygon, multiPolygon, lineString];

  static const _types = [string, number, ...spatial];

  /// Returns the [DataType] constant corresponding to the specified [type].
  static DataType? tryParse(dynamic type) =>
      _types.firstOrDefault((m) => m.name == type);
}
