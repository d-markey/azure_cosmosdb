import 'dart:convert';
import 'dart:math';

import 'package:azure_cosmosdb/azure_cosmosdb.dart';
import 'package:test/test.dart';

void main() async {
  run();
}

void run() {
  test('Serialize a point', () async {
    final p = Point.geometry(2, 3);
    final json = jsonDecode(jsonEncode(p));
    expect(json, isA<Map>());
    expect(json['type'], equals(DataType.point.name));

    final coordinates = json['coordinates'];
    expect(coordinates, isA<List>());
    expect(coordinates.length, equals(2));
    expect(coordinates[0], equals(p.x));
    expect(coordinates[1], equals(p.y));
  });

  test('Deserialize a point', () async {
    final p = Point.geometry(2, 3);

    final json = jsonDecode(jsonEncode(p));

    final dp = Point.fromGeoJson(json, GeospatialConfig.geometry);
    expect(dp.x, equals(p.x));
    expect(dp.y, equals(p.y));
  });

  test('Create a 2D line', () async {
    final line = LineString();
    expect(line.isEmpty, isTrue);
    expect(line.isNotEmpty, isFalse);
    line.add(Point.geometry(0, 0));
    expect(line.isEmpty, isFalse);
    expect(line.isNotEmpty, isTrue);
    line.add(Point.geometry(2, 2));
    expect(line.isEmpty, isFalse);
    expect(line.isNotEmpty, isTrue);
  });

  test('Serialize a 2D line', () async {
    final line = LineString();
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

  test('Deserialize a 2D line', () async {
    final line = LineString();
    line.add(Point.geometry(0, 1));
    line.add(Point.geometry(2, 3));

    final json = jsonDecode(jsonEncode(line));

    final dline = LineString.fromGeoJson(json, GeospatialConfig.geometry);
    expect(dline.points.length, equals(line.points.length));
    for (var i = 0; i < line.points.length; i++) {
      final p = line.points.elementAt(i);
      final dp = dline.points.elementAt(i);
      expect(dp.x, equals(p.x));
      expect(dp.y, equals(p.y));
    }
  });

  test('Measure a 2D line', () async {
    final line = LineString();
    line.add(Point.geometry(0, 0));
    line.add(Point.geometry(2, 2));
    final dist2D = DistanceCalculator2D();
    var d2D = dist2D.measure(line);
    expect(d2D, equals(sqrt(8)));
    final dist3D = DistanceCalculator3D();
    var d3D = dist3D.measure(line);
    expect(d3D, equals(sqrt(8)));
  });

  test('Create a 3D line', () async {
    final line = LineString();
    expect(line.isEmpty, isTrue);
    expect(line.isNotEmpty, isFalse);
    line.add(Point.geometry(0, 0, 0));
    expect(line.isEmpty, isFalse);
    expect(line.isNotEmpty, isTrue);
    line.add(Point.geometry(2, 2, 2));
  });

  test('Measure a 3D line', () async {
    final line = LineString();
    line.add(Point.geometry(0, 0, 0));
    line.add(Point.geometry(2, 2, 2));
    final dist2D = DistanceCalculator2D();
    var d2D = dist2D.measure(line);
    expect(d2D, equals(sqrt(8)));
    final dist3D = DistanceCalculator3D();
    var d3D = dist3D.measure(line);
    expect(d3D, equals(sqrt(12)));
  });

  test('Create a 2D triangle', () async {
    final triangle = Polygon();
    expect(triangle.isEmpty, isTrue);
    expect(triangle.isNotEmpty, isFalse);
    triangle.add(LineString()
      ..addAll([
        Point.geometry(0, 0),
        Point.geometry(1, 1),
        Point.geometry(2, 0),
      ]));
    expect(triangle.isEmpty, isFalse);
    expect(triangle.isNotEmpty, isTrue);
  });

  test('Serialize a 2D triangle', () async {
    final triangle = Polygon();
    triangle.add(LineString()
      ..addAll([
        Point.geometry(0, 0),
        Point.geometry(1, 1),
        Point.geometry(2, 0),
      ]));

    final json = jsonDecode(jsonEncode(triangle));
    expect(json, isA<Map>());
    expect(json['type'], equals(DataType.polygon.name));

    final coordinates = json['coordinates'][0];
    final pos = triangle.rings.first.points.toList();
    expect(coordinates, isA<List>());
    // one more coordinate as the first point is repeated in json
    expect(coordinates.length, equals(pos.length + 1));
    expect(coordinates[0][0], equals(pos[0].x));
    expect(coordinates[0][1], equals(pos[0].y));
    expect(coordinates[1][0], equals(pos[1].x));
    expect(coordinates[1][1], equals(pos[1].y));
    expect(coordinates[2][0], equals(pos[2].x));
    expect(coordinates[2][1], equals(pos[2].y));
    // last point in json = first point in ring
    expect(coordinates[3][0], equals(pos[0].x));
    expect(coordinates[3][1], equals(pos[0].y));
  });

  test('Deserialize a 2D triangle', () async {
    final triangle = Polygon();
    triangle.add(LineString()
      ..addAll([
        Point.geometry(0, 0),
        Point.geometry(1, 1),
        Point.geometry(2, 0),
      ]));

    final json = jsonDecode(jsonEncode(triangle));

    final dtriangle =
        Shape.fromGeoJson<Polygon>(json, GeospatialConfig.geometry);
    expect(dtriangle.rings.length, equals(dtriangle.rings.length));
    for (var i = 0; i < triangle.rings.length; i++) {
      var r = triangle.rings.elementAt(i);
      var dr = dtriangle.rings.elementAt(i);
      expect(dr.points.length, equals(r.points.length));
      for (var j = 0; j < r.points.length; j++) {
        final p = r.points.elementAt(j);
        final dp = dr.points.elementAt(j);
        expect(dp.x, equals(p.x));
        expect(dp.y, equals(p.y));
      }
    }
  });

  test('Measure a 2D triangle', () async {
    final triangle = Polygon();
    triangle.add(LineString()
      ..addAll([
        Point.geometry(0, 0),
        Point.geometry(1, 1),
        Point.geometry(2, 0),
      ]));
    final dist2D = DistanceCalculator2D();
    var d2D = dist2D.measure(triangle);
    expect(d2D, equals(2 + 2 * sqrt(2)));
    final dist3D = DistanceCalculator3D();
    var d3D = dist3D.measure(triangle);
    expect(d3D, equals(2 + 2 * sqrt(2)));
  });

  test('Create a 3D triangle', () async {
    final triangle = Polygon();
    expect(triangle.isEmpty, isTrue);
    expect(triangle.isNotEmpty, isFalse);
    triangle.add(LineString()
      ..addAll([
        Point.geometry(0, 0, 0),
        Point.geometry(1, 1, 1),
        Point.geometry(2, 0, 2),
      ]));
    expect(triangle.isEmpty, isFalse);
    expect(triangle.isNotEmpty, isTrue);
  });

  test('Measure a 3D triangle', () async {
    final triangle = Polygon();
    triangle.add(LineString()
      ..addAll([
        Point.geometry(0, 0, 0),
        Point.geometry(1, 1, 1),
        Point.geometry(2, 0, 2),
      ]));
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
    triangle.add(LineString()
      ..addAll([
        Point.geometry(0, 0, 0),
        Point.geometry(1, 1, 1),
        Point.geometry(2, 0),
      ]));
    expect(triangle.isEmpty, isFalse);
    expect(triangle.isNotEmpty, isTrue);
  });

  test('Measure a mixed 2D/3D triangle', () async {
    final triangle = Polygon();
    triangle.add(LineString()
      ..addAll([
        Point.geometry(0, 0, 0),
        Point.geometry(1, 1, 1),
        Point.geometry(2, 0),
      ]));
    final dist2D = DistanceCalculator2D();
    var d2D = dist2D.measure(triangle);
    expect(d2D, equals(2 + 2 * sqrt(2)));
    final dist3D = DistanceCalculator3D();
    var d3D = dist3D.measure(triangle);
    expect(d3D, equals(2 + sqrt(3) + sqrt(2)));
  });

  test('Create a multi-polygon', () async {
    final triangle = Polygon();
    triangle.add(LineString()
      ..addAll([
        Point.geometry(0, 0),
        Point.geometry(1, 1),
        Point.geometry(2, 0),
      ]));
    final square = Polygon();
    square.add(LineString()
      ..addAll([
        Point.geometry(-10, -10),
        Point.geometry(-10, 10),
        Point.geometry(10, 10),
        Point.geometry(10, -10)
      ]));
    final multi = MultiPolygon();
    expect(multi.isEmpty, isTrue);
    expect(multi.isNotEmpty, isFalse);
    multi.addAll([triangle, square]);
    expect(multi.isEmpty, isFalse);
    expect(multi.isNotEmpty, isTrue);
  });

  test('Serialize a multi-polygon', () async {
    final triangle = Polygon();
    triangle.add(LineString()
      ..addAll([
        Point.geometry(0, 0),
        Point.geometry(1, 1),
        Point.geometry(2, 0),
      ]));
    final square = Polygon();
    square.add(LineString()
      ..addAll([
        Point.geometry(-10, -10),
        Point.geometry(-10, 10),
        Point.geometry(10, 10),
        Point.geometry(10, -10)
      ]));
    final multi = MultiPolygon();
    multi.addAll([triangle, square]);

    final json = jsonDecode(jsonEncode(multi));
    expect(json, isA<Map>());
    expect(json['type'], equals(DataType.multiPolygon.name));

    final jsonTriangle = json['coordinates'][0][0];
    final trianglePos = triangle.rings.first.points.toList();
    expect(jsonTriangle, isA<List>());
    expect(jsonTriangle.length, equals(trianglePos.length + 1));
    expect(jsonTriangle[0][0], equals(trianglePos[0].x));
    expect(jsonTriangle[0][1], equals(trianglePos[0].y));
    expect(jsonTriangle[1][0], equals(trianglePos[1].x));
    expect(jsonTriangle[1][1], equals(trianglePos[1].y));
    expect(jsonTriangle[2][0], equals(trianglePos[2].x));
    expect(jsonTriangle[2][1], equals(trianglePos[2].y));
    expect(jsonTriangle[3][0], equals(trianglePos[0].x));
    expect(jsonTriangle[3][1], equals(trianglePos[0].y));

    final jsonSquare = json['coordinates'][1][0];
    final squarePos = square.rings.first.points.toList();
    expect(jsonSquare, isA<List>());
    expect(jsonSquare.length, equals(squarePos.length + 1));
    expect(jsonSquare[0][0], equals(squarePos[0].x));
    expect(jsonSquare[0][1], equals(squarePos[0].y));
    expect(jsonSquare[1][0], equals(squarePos[1].x));
    expect(jsonSquare[1][1], equals(squarePos[1].y));
    expect(jsonSquare[2][0], equals(squarePos[2].x));
    expect(jsonSquare[2][1], equals(squarePos[2].y));
    expect(jsonSquare[3][0], equals(squarePos[3].x));
    expect(jsonSquare[3][1], equals(squarePos[3].y));
    expect(jsonSquare[4][0], equals(squarePos[0].x));
    expect(jsonSquare[4][1], equals(squarePos[0].y));
  });

  test('Deserialize a multi-polygon', () async {
    final triangle = Polygon();
    triangle.add(LineString()
      ..addAll([
        Point.geometry(0, 0),
        Point.geometry(1, 1),
        Point.geometry(2, 0),
      ]));
    final square = Polygon();
    square.add(LineString()
      ..addAll([
        Point.geometry(-10, -10),
        Point.geometry(-10, 10),
        Point.geometry(10, 10),
        Point.geometry(10, -10)
      ]));
    final multi = MultiPolygon();
    multi.addAll([triangle, square]);

    final json = jsonDecode(jsonEncode(multi));

    final dmulti = MultiPolygon.fromGeoJson(json, GeospatialConfig.geometry);
    expect(dmulti.polygons.length, equals(multi.polygons.length));
    for (var i = 0; i < multi.polygons.length; i++) {
      var p = multi.polygons.elementAt(i);
      var dp = dmulti.polygons.elementAt(i);
      expect(dp.rings.length, equals(p.rings.length));
      for (var j = 0; j < p.rings.length; j++) {
        var r = p.rings.elementAt(j);
        var dr = dp.rings.elementAt(j);
        expect(dr.points.length, equals(r.points.length));
        for (var k = 0; k < r.points.length; k++) {
          var pt = r.points.elementAt(k);
          var dpt = dr.points.elementAt(k);
          expect(dpt.x, equals(pt.x));
          expect(dpt.y, equals(pt.y));
        }
      }
    }
  });
}
