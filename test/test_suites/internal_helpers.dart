import 'package:azure_cosmosdb/src/_internal/_linq_extensions.dart';
import 'package:test/test.dart';

void main() async {
  run();
}

void run() {
  final emptyList = <Map<String, dynamic>>[];

  final list = <Map<String, dynamic>>[
    {'id': 1, 'value': 'one'},
    {'id': 2, 'value': 'two'},
    {'id': 3, 'value': 'three'},
  ];

  final dupList = <Map<String, dynamic>>[
    {'id': 1, 'value': 'one'},
    {'id': 2, 'value': 'two #1'},
    {'id': 2, 'value': 'two #2'},
    {'id': 3, 'value': 'three'},
  ];

  test('firstOrDefault()', () async {
    final found = list.firstOrDefault((item) => item['id'] == 2);
    expect(found, isNotNull);
    expect(found!['id'], equals(2));
  });

  test('firstOrDefault() - multiple matches', () async {
    final found = dupList.firstOrDefault((item) => item['id'] == 2);
    expect(found, isNotNull);
    expect(found!['id'], equals(2));
    expect(found['value'], equals('two #1'));
  });

  test('firstOrDefault() - no match', () async {
    final notFound = list.firstOrDefault((item) => item['id'] == 0);
    expect(notFound, isNull);
  });

  test('firstOrDefault - empty set', () async {
    final notFound = emptyList.firstOrDefault((item) => item['id'] == 2);
    expect(notFound, isNull);
  });

  test('singleOrDefault()', () async {
    final found = list.singleOrDefault((item) => item['id'] == 2);
    expect(found, isNotNull);
    expect(found!['id'], equals(2));
  });

  test('singleOrDefault() - multiple matches', () async {
    try {
      dupList.singleOrDefault((item) => item['id'] == 2);
      throw Exception('singleOrDefault() returned a value unexpectedly');
    } on LinqException {
      // expected exception
    }
  });

  test('singleOrDefault() - no match', () async {
    final notFound = list.firstOrDefault((item) => item['id'] == 0);
    expect(notFound, isNull);
  });

  test('firstOrDefault - empty set', () async {
    final notFound = emptyList.singleOrDefault((item) => item['id'] == 2);
    expect(notFound, isNull);
  });
}
