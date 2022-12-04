import 'dart:convert';
import 'dart:math';

import 'package:azure_cosmosdb/azure_cosmosdb.dart';
import 'package:test/test.dart';

void main() async {
  run();
}

void run() {
  test('Create a simple 2D line', () async {
    final line = Line();
    expect(line.isEmpty, isTrue);
    expect(line.isNotEmpty, isFalse);
    line.add(Point.geometry(0, 0));
    expect(line.isEmpty, isFalse);
    expect(line.isNotEmpty, isTrue);
    line.add(Point.geometry(2, 2));
    expect(line.isEmpty, isFalse);
    expect(line.isNotEmpty, isTrue);
  });

  test('Serialize a simple 2D line', () async {
    final line = Line();
    line.add(Point.geometry(0, 1));
    line.add(Point.geometry(2, 3));

    final json = jsonDecode(jsonEncode(line));
    expect(json, isA<Map>());
    expect(json['type'], equals(DataType.lineString.name));

    final coordinates = json['coordinates'];
    final pos = line.points.toList();
    expect(coordinates, isA<List>());
    expect(coordinates.length, equals(pos.length));
    expect(coordinates[0][0], equals(pos[0].x));
    expect(coordinates[0][1], equals(pos[0].y));
    expect(coordinates[1][0], equals(pos[1].x));
    expect(coordinates[1][1], equals(pos[1].y));
  });

  test('Measure a simple 2D line', () async {
    final line = Line();
    line.add(Point.geometry(0, 0));
    line.add(Point.geometry(2, 2));
    final dist2D = DistanceCalculator2D();
    var d2D = dist2D.measure(line);
    expect(d2D, equals(sqrt(8)));
    final dist3D = DistanceCalculator3D();
    var d3D = dist3D.measure(line);
    expect(d3D, equals(sqrt(8)));
  });

  test('Create a simple 3D line', () async {
    final line = Line();
    expect(line.isEmpty, isTrue);
    expect(line.isNotEmpty, isFalse);
    line.add(Point.geometry(0, 0, 0));
    expect(line.isEmpty, isFalse);
    expect(line.isNotEmpty, isTrue);
    line.add(Point.geometry(2, 2, 2));
  });

  test('Measure a simple 3D line', () async {
    final line = Line();
    line.add(Point.geometry(0, 0, 0));
    line.add(Point.geometry(2, 2, 2));
    final dist2D = DistanceCalculator2D();
    var d2D = dist2D.measure(line);
    expect(d2D, equals(sqrt(8)));
    final dist3D = DistanceCalculator3D();
    var d3D = dist3D.measure(line);
    expect(d3D, equals(sqrt(12)));
  });

  test('Create a simple 2D triangle', () async {
    final triangle = Polygon();
    expect(triangle.isEmpty, isTrue);
    expect(triangle.isNotEmpty, isFalse);
    triangle.addAll([
      Point.geometry(0, 0),
      Point.geometry(1, 1),
      Point.geometry(2, 0),
    ]);
    expect(triangle.isEmpty, isFalse);
    expect(triangle.isNotEmpty, isTrue);
  });

  test('Serialize a simple 2D triangle', () async {
    final triangle = Polygon();
    triangle.addAll([
      Point.geometry(0, 0),
      Point.geometry(1, 1),
      Point.geometry(2, 0),
    ]);

    final json = jsonDecode(jsonEncode(triangle));
    expect(json, isA<Map>());
    expect(json['type'], equals(DataType.polygon.name));

    final coordinates = json['coordinates'];
    final pos = triangle.points.toList();
    expect(coordinates, isA<List>());
    expect(coordinates.length, equals(pos.length));
    expect(coordinates[0][0], equals(pos[0].x));
    expect(coordinates[0][1], equals(pos[0].y));
    expect(coordinates[1][0], equals(pos[1].x));
    expect(coordinates[1][1], equals(pos[1].y));
    expect(coordinates[2][0], equals(pos[2].x));
    expect(coordinates[2][1], equals(pos[2].y));
    expect(coordinates[3][0], equals(pos[3].x));
    expect(coordinates[3][1], equals(pos[3].y));
  });

  test('Measure a simple 2D triangle', () async {
    final triangle = Polygon();
    triangle.addAll([
      Point.geometry(0, 0),
      Point.geometry(1, 1),
      Point.geometry(2, 0),
    ]);
    final dist2D = DistanceCalculator2D();
    var d2D = dist2D.measure(triangle);
    expect(d2D, equals(2 + 2 * sqrt(2)));
    final dist3D = DistanceCalculator3D();
    var d3D = dist3D.measure(triangle);
    expect(d3D, equals(2 + 2 * sqrt(2)));
  });

  test('Create a simple 3D triangle', () async {
    final triangle = Polygon();
    expect(triangle.isEmpty, isTrue);
    expect(triangle.isNotEmpty, isFalse);
    triangle.addAll([
      Point.geometry(0, 0, 0),
      Point.geometry(1, 1, 1),
      Point.geometry(2, 0, 2),
    ]);
    expect(triangle.isEmpty, isFalse);
    expect(triangle.isNotEmpty, isTrue);
  });

  test('Measure a simple 3D triangle', () async {
    final triangle = Polygon();
    triangle.addAll([
      Point.geometry(0, 0, 0),
      Point.geometry(1, 1, 1),
      Point.geometry(2, 0, 2),
    ]);
    final dist2D = DistanceCalculator2D();
    var d2D = dist2D.measure(triangle);
    expect(d2D, equals(2 + 2 * sqrt(2)));
    final dist3D = DistanceCalculator3D();
    var d3D = dist3D.measure(triangle);
    expect(d3D, equals(sqrt(8) + 2 * sqrt(3)));
  });

  test('Create a mixed 2D/3D triangle', () async {
    final triangle = Polygon();
    expect(triangle.isEmpty, isTrue);
    expect(triangle.isNotEmpty, isFalse);
    triangle.addAll([
      Point.geometry(0, 0, 0),
      Point.geometry(1, 1, 1),
      Point.geometry(2, 0),
    ]);
    expect(triangle.isEmpty, isFalse);
    expect(triangle.isNotEmpty, isTrue);
  });

  test('Measure a mixed 2D/3D triangle', () async {
    final triangle = Polygon();
    triangle.addAll([
      Point.geometry(0, 0, 0),
      Point.geometry(1, 1, 1),
      Point.geometry(2, 0),
    ]);
    final dist2D = DistanceCalculator2D();
    var d2D = dist2D.measure(triangle);
    expect(d2D, equals(2 + 2 * sqrt(2)));
    final dist3D = DistanceCalculator3D();
    var d3D = dist3D.measure(triangle);
    expect(d3D, equals(2 + sqrt(3) + sqrt(2)));
  });

  test('Create a multi-polygon', () async {
    final triangle = Polygon();
    triangle.addAll([
      Point.geometry(0, 0),
      Point.geometry(1, 1),
      Point.geometry(2, 0),
    ]);
    final square = Polygon();
    square.addAll([
      Point.geometry(-10, -10),
      Point.geometry(-10, 10),
      Point.geometry(10, 10),
      Point.geometry(10, -10)
    ]);
    final multi = MultiPolygon();
    expect(multi.isEmpty, isTrue);
    expect(multi.isNotEmpty, isFalse);
    multi.polygons.add(triangle);
    multi.polygons.add(square);
    expect(multi.isEmpty, isFalse);
    expect(multi.isNotEmpty, isTrue);
  });

  test('Serialize a multi-polygon', () async {
    final triangle = Polygon();
    triangle.addAll([
      Point.geometry(0, 0),
      Point.geometry(1, 1),
      Point.geometry(2, 0),
    ]);
    final square = Polygon();
    square.addAll([
      Point.geometry(-10, -10),
      Point.geometry(-10, 10),
      Point.geometry(10, 10),
      Point.geometry(10, -10)
    ]);
    final multi = MultiPolygon();
    multi.polygons.add(triangle);
    multi.polygons.add(square);

    final json = jsonDecode(jsonEncode(multi));
    expect(json, isA<Map>());
    expect(json['type'], equals(DataType.multiPolygon.name));

    final jsonTriangle = json['coordinates'][0];
    final trianglePos = triangle.points.toList();
    expect(jsonTriangle, isA<List>());
    expect(jsonTriangle.length, equals(trianglePos.length));
    expect(jsonTriangle[0][0], equals(trianglePos[0].x));
    expect(jsonTriangle[0][1], equals(trianglePos[0].y));
    expect(jsonTriangle[1][0], equals(trianglePos[1].x));
    expect(jsonTriangle[1][1], equals(trianglePos[1].y));
    expect(jsonTriangle[2][0], equals(trianglePos[2].x));
    expect(jsonTriangle[2][1], equals(trianglePos[2].y));
    expect(jsonTriangle[3][0], equals(trianglePos[3].x));
    expect(jsonTriangle[3][1], equals(trianglePos[3].y));

    final jsonSquare = json['coordinates'][1];
    final squarePos = square.points.toList();
    expect(jsonSquare, isA<List>());
    expect(jsonSquare.length, equals(squarePos.length));
    expect(jsonSquare[0][0], equals(squarePos[0].x));
    expect(jsonSquare[0][1], equals(squarePos[0].y));
    expect(jsonSquare[1][0], equals(squarePos[1].x));
    expect(jsonSquare[1][1], equals(squarePos[1].y));
    expect(jsonSquare[2][0], equals(squarePos[2].x));
    expect(jsonSquare[2][1], equals(squarePos[2].y));
    expect(jsonSquare[3][0], equals(squarePos[3].x));
    expect(jsonSquare[3][1], equals(squarePos[3].y));
    expect(jsonSquare[4][0], equals(squarePos[4].x));
    expect(jsonSquare[4][1], equals(squarePos[4].y));
  });
}
