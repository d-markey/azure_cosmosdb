import 'dart:convert';

import 'package:azure_cosmosdb/azure_cosmosdb.dart';
import 'package:test/test.dart';

import '../classes/spatial_data_sets.dart';

void main() async {
  run();
}

void run() {
  test('Create a line', () async {
    final line = LineString();
    expect(line.isEmpty, isTrue);
    expect(line.isNotEmpty, isFalse);
    line.add(cities['Paris']!); // Paris
    expect(line.isEmpty, isFalse);
    expect(line.isNotEmpty, isTrue);
    line.add(cities['New-York']!); // New York
    expect(line.isEmpty, isFalse);
    expect(line.isNotEmpty, isTrue);
  });

  test('Serialize a line', () async {
    final line = LineString();
    line.addAll([
      cities['Paris']!,
      cities['New-York']!,
    ]);

    final json = jsonDecode(jsonEncode(line));
    expect(json, isA<Map>());
    expect(json['type'], equals(DataType.lineString.name));

    final coords = json['coordinates'];
    expect(coords, isA<List>());
    expect(coords.length, equals(2));

    for (var i = 0; i < coords.length; i++) {
      var p = line.points.elementAt(i);
      expect(coords[i][0], equals(p.longitude));
      expect(coords[i][1], equals(p.latitude));
    }
  });

  test('Deserialize a line', () async {
    final line = LineString();
    line.addAll([
      cities['Paris']!,
      cities['New-York']!,
    ]);

    final json = jsonDecode(jsonEncode(line));

    final dline = LineString.fromGeoJson(json, GeospatialConfig.geography);
    expect(dline.points.length, equals(line.points.length));
    for (var i = 0; i < line.points.length; i++) {
      var p = line.points.elementAt(i);
      var dp = dline.points.elementAt(i);
      expect(dp.latitude, equals(p.latitude));
      expect(dp.longitude, equals(p.longitude));
    }
  });

  test('Serialize a polygon', () async {
    final poly = parisArea;

    final json = jsonDecode(jsonEncode(poly));
    expect(json, isA<Map>());
    expect(json['type'], equals(DataType.polygon.name));

    final coords = json['coordinates'];
    expect(coords, isA<List>());
    expect(coords.length, equals(poly.rings.length));

    var r = coords[0];
    expect(r, isA<List>());
    expect(r.length, equals(poly.rings.first.points.length + 1));
    for (var i = 0; i < poly.rings.first.points.length; i++) {
      var p = poly.rings.first.points.elementAt(i);
      expect(r[i][0], equals(p.longitude));
      expect(r[i][1], equals(p.latitude));
    }
  });

  test('Deserialize a polygon', () async {
    final poly = parisArea;

    final json = jsonDecode(jsonEncode(poly));

    final dpoly = Polygon.fromGeoJson(json, GeospatialConfig.geography);
    expect(dpoly.rings.length, equals(poly.rings.length));
    for (var i = 0; i < poly.rings.length; i++) {
      var r = poly.rings.elementAt(i);
      var dr = dpoly.rings.elementAt(i);
      expect(dr.points.length, equals(r.points.length));
      for (var j = 0; j < r.points.length; j++) {
        var p = r.points.elementAt(j);
        var dp = dr.points.elementAt(j);
        expect(dp.latitude, p.latitude);
        expect(dp.longitude, p.longitude);
      }
    }
  });

  test('Long distances (cities)', () async {
    for (final from in cities.entries) {
      for (final to
          in cities.entries.where((t) => t.key.compareTo(from.key) >= 0)) {
        final expected = cityDistances['${from.key}->${to.key}']!;
        _checkDistance(from.value, to.value, expected);
      }
    }
  });

  test('Short distances (monuments)', () async {
    // Paris
    _checkDistance(
      monuments['Eiffel Tower']!,
      monuments['Notre Dame de Paris']!,
      4.1,
    );

    // London
    _checkDistance(
      monuments['London Tower Bridge']!,
      monuments['Big Ben']!,
      3.5,
    );

    // New-York
    _checkDistance(
      monuments['Statue of Liberty']!,
      monuments['Empire State Building']!,
      8.3,
    );
  });
}

void _checkDistance(Point from, Point to, double expected) {
  final line = LineString();
  line.addAll([from, to]);
  final distance = earthDistanceCalculator.measure(line)!;
  final diff = (expected - distance).abs();
  if (expected < 10) {
    // error < 100 meters for short distances (under 10 km)
    expect(diff, lessThanOrEqualTo(0.1));
  } else {
    // error < 0.1% for longer distances
    expect((100 * diff) / expected, lessThan(0.1));
  }
}
