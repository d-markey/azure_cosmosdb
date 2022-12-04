import 'package:azure_cosmosdb/azure_cosmosdb.dart';
import 'package:test/test.dart';

void main() async {
  run();
}

const _cities = {
  'Berlin': Point.geography(52.520007, 13.404954),
  'Canberra': Point.geography(-35.28467, 149.13522),
  'London': Point.geography(51.5073509, -0.1277583),
  'New-York': Point.geography(40.712784, -74.005941),
  'Paris': Point.geography(48.856613, 2.342889),
  'Ushuaia': Point.geography(-54.8019121, -68.3029511),
};

const _distances = <String, double>{
  // Berlin
  'Berlin->Berlin': 0,
  'Berlin->Canberra': 16056,
  'Berlin->London': 932,
  'Berlin->New-York': 6385,
  'Berlin->Paris': 878,
  'Berlin->Ushuaia': 14092,
  // Canberra
  'Canberra->Canberra': 0,
  'Canberra->London': 16971,
  'Canberra->New-York': 16215,
  'Canberra->Paris': 16909,
  'Canberra->Ushuaia': 9379,
  // London
  'London->London': 0,
  'London->New-York': 5571,
  'London->Paris': 343,
  'London->Ushuaia': 13381,
  // New-York
  'New-York->New-York': 0,
  'New-York->Paris': 5836,
  'New-York->Ushuaia': 10631,
  // Paris
  'Paris->Paris': 0,
  'Paris->Ushuaia': 13260,
  // Ushuaia
  'Ushuaia->Ushuaia': 0,
};

void run() {
  test('Create a simple line', () async {
    final line = Line();
    expect(line.isEmpty, isTrue);
    expect(line.isNotEmpty, isFalse);
    line.add(_cities['Paris']!); // Paris
    expect(line.isEmpty, isFalse);
    expect(line.isNotEmpty, isTrue);
    line.add(_cities['New-York']!); // New York
    expect(line.isEmpty, isFalse);
    expect(line.isNotEmpty, isTrue);
  });

  test('Long distances (cities)', () async {
    final cities = _cities.entries;
    for (final from in cities) {
      for (final to in cities.where((t) => t.key.compareTo(from.key) >= 0)) {
        final expected = _distances['${from.key}->${to.key}']!;
        _checkDistance(from.value, to.value, expected);
      }
    }
  });

  test('Short distances (monuments)', () async {
    // Paris
    _checkDistance(
      Point.geography(48.858370, 2.294481), // Eiffel Tower
      Point.geography(48.852968, 2.349902), // Notre Dame de Paris
      4.1,
    );

    // London
    _checkDistance(
      Point.geography(51.50562, -0.07537), // Tower Bridge
      Point.geography(51.50108, -0.12462), // Big Ben
      3.5,
    );

    // New-York
    _checkDistance(
      Point.geography(40.689247, -74.044502), // Statue of Liberty
      Point.geography(40.748817, -73.985428), // Empire State Building
      8.3,
    );
  });
}

void _checkDistance(Point from, Point to, double expected) {
  final line = Line();
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
