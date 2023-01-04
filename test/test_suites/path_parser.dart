import 'package:azure_cosmosdb/src/partition/_path_parser.dart';
import 'package:test/test.dart';

void main() async {
  run();
}

void run() {
  test('Simple path', () {
    final path = PathParser();
    final components = path.parse('/id');
    expect(components, equals([PathSegment('id')]));

    final json = {'id': 'ok'};
    expect(components.extract(json), equals('ok'));
  });

  test('Simple path with escaped name', () {
    final path = PathParser();
    final components = path.parse('/"due-date"');
    expect(components, equals([PathSegment('due-date')]));

    final date = DateTime.now().toUtc();
    final json = {'due-date': date};
    expect(components.extract(json), equals(date));
  });

  test('Composite path', () {
    final path = PathParser();
    final components = path.parse('/pos/lat');
    expect(components, equals([PathSegment('pos'), PathSegment('lat')]));

    final json = {
      'pos': {'lat': 1.234}
    };
    expect(components.extract(json), equals(1.234));
  });

  test('Array index', () {
    final path = PathParser();
    final components = path.parse('/groups[1]');
    expect(components, equals([PathSegment('groups'), ArrayIndex(1)]));

    final json = {
      'groups': ['ko', 'ok', 'ko']
    };
    expect(components.extract(json), equals('ok'));
  });
}
