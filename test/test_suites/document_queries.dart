import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';
import 'package:test/test.dart';

import '../classes/spatial_data_sets.dart';
import '../classes/test_document.dart';
import '../classes/test_helpers.dart';
import '../classes/test_spatial_document_point.dart';

void main() async {
  final cosmosDB = await getTestInstance();
  if (cosmosDB != null) {
    run(cosmosDB);
  }
}

void run(CosmosDbServer cosmosDB) {
  late final CosmosDbDatabase database;
  late final CosmosDbCollection collection;
  late final CosmosDbCollection spatialCollection;

  setUpAll(() async {
    database = await cosmosDB.databases.create(getTempName());
    collection = await database.collections.create(
      'items',
      partitionKeys: ['/id'],
    );
    collection.registerBuilder<TestDocument>(TestDocument.fromJson);
    await collection.add(TestDocument('1', 'PRIME #1', [2, 3, 5]));
    await collection.add(TestDocument('2', 'PRIME #2', [7, 11, 13]));
    await collection.add(TestDocument('3', 'EVEN', [2, 4, 6]));

    final indexingPolicy = IndexingPolicy();
    indexingPolicy.spatialIndexes.add(SpatialIndexPath('/p/?'));
    spatialCollection = await database.collections.create(
      'areas',
      partitionKeys: ['/id'],
      indexingPolicy: indexingPolicy,
    );
    spatialCollection.registerBuilder<TestSpatialDocumentPoint>(
        TestSpatialDocumentPoint.fromJson);
    await spatialCollection.add(TestSpatialDocumentPoint(
      'flt',
      'Eiffel Tower',
      monuments['Eiffel Tower']!,
    ));
    await spatialCollection.add(TestSpatialDocumentPoint(
      'bbn',
      'Big Ben',
      monuments['Big Ben']!,
    ));
  });

  tearDownAll(() async {
    await cosmosDB.databases.delete(database);
  });

  test('List documents', () async {
    final list = await collection.list<TestDocument>();
    expect(list.length, equals(3));
  });

  test('Query single documents', () async {
    final query = Query(
      'SELECT * FROM doc WHERE doc.id=@id',
      partition: CosmosDbPartition('1'),
      params: {'@id': '1'},
    );

    var res = await collection.query<TestDocument>(query);
    expect(res.length, equals(1));
    expect(res.first.id, equals('1'));
  });

  test('Query on wrong partition yields no documents', () async {
    final query = Query(
      'SELECT * FROM doc WHERE doc.id=@id',
      partition: CosmosDbPartition('2'),
      params: {'@id': '1'},
    );

    var res = await collection.query<TestDocument>(query);
    expect(res, isEmpty);
  });

  test('Cross-partition query', () async {
    final query = Query(
      'SELECT * FROM doc WHERE doc.id=@id1 OR doc.id=@id2',
      partition: CosmosDbPartition('1'),
      params: {'@id1': '1', '@id2': '3'},
    );

    var res = await collection.query<TestDocument>(query);
    expect(res.length, equals(1));
    expect(res.first.id, equals('1'));

    query.onPartition('2');
    res = await collection.query<TestDocument>(query);
    expect(res, isEmpty);

    query.onPartition('3');
    res = await collection.query<TestDocument>(query);
    expect(res.length, equals(1));
    expect(res.first.id, equals('3'));

    query.crossPartition();
    res = await collection.query<TestDocument>(query);
    expect(res.length, equals(2));
  });

  test('Query multiple documents', () async {
    // /!\ NOTE: TestDocuments serialize as { 'id': id , 'l': label, 'd': data}
    // /!\ NOTE: to match the label, the query must use 'doc.l'
    final query = Query('SELECT * FROM doc WHERE CONTAINS(doc.l, @text)',
        params: {'@text': 'PRIME'}, partition: CosmosDbPartition.all);
    final res = await collection.query<TestDocument>(query);
    expect(res.length, equals(2));
    expect(query.continuation, isEmpty);
  });

  test('Query multiple documents with paging', () async {
    final query = Query('SELECT * FROM doc WHERE CONTAINS(doc.l, @text)',
        params: {'@text': 'PRIME'},
        partition: CosmosDbPartition.all,
        maxCount: 1);

    final res1 = await collection.query<TestDocument>(query);
    expect(query.continuation, isNotEmpty);
    expect(res1.length, equals(1));

    final res2 = await collection.query<TestDocument>(query);
    expect(query.continuation, isEmpty);
    expect(res2.length, equals(1));

    expect(res1.first.id == res2.first.id, isFalse);
  });

  test('Check spatial dataset - Points', () async {
    Query q;
    dynamic r;

    for (var entry in cities.entries) {
      q = Query(
        'SELECT ST_ISVALIDDETAILED(@${entry.key.replaceAll('-', '')})',
        partition: CosmosDbPartition.all,
        params: {'@${entry.key.replaceAll('-', '')}': entry.value},
      );
      r = await spatialCollection.rawQuery(q);
      expect(r['Documents'][0]['\$1']['valid'], isTrue);
    }

    for (var entry in monuments.entries) {
      q = Query(
        'SELECT ST_ISVALIDDETAILED(@${entry.key.replaceAll(' ', '')})',
        partition: CosmosDbPartition.all,
        params: {'@${entry.key.replaceAll(' ', '')}': entry.value},
      );
      r = await spatialCollection.rawQuery(q);
      expect(r['Documents'][0]['\$1']['valid'], isTrue);
    }
  });

  test('Check spatial dataset - LineString', () async {
    Query q;
    dynamic r;

    q = Query(
      'SELECT ST_ISVALIDDETAILED(@flight)',
      partition: CosmosDbPartition.all,
      params: {
        '@flight': LineString()
          ..addAll([
            cities['Paris']!,
            cities['London']!,
          ])
      },
    );
    r = await spatialCollection.rawQuery(q);
    expect(r['Documents'][0]['\$1']['valid'], isTrue);
  });

  test('Check spatial dataset - Polygon', () async {
    Query q;
    dynamic r;

    for (var entry in {
      'P': parisArea,
      'B': boisDeBoulogneArea,
      'V': boisDeVincennesArea
    }.entries) {
      q = Query(
        'SELECT ST_ISVALIDDETAILED(@${entry.key})',
        partition: CosmosDbPartition.all,
        params: {'@${entry.key}': entry.value},
      );
      r = await spatialCollection.rawQuery(q);
      expect(r['Documents'][0]['\$1']['valid'], isTrue);
    }
  });

  test('Check spatial dataset - MultiPolygon', () async {
    Query q;
    dynamic r;

    q = Query(
      'SELECT ST_ISVALIDDETAILED(@multi)',
      partition: CosmosDbPartition.all,
      params: {
        '@multi': MultiPolygon()
          ..addAll([
            boisDeBoulogneArea,
            boisDeVincennesArea,
          ])
      },
    );
    r = await spatialCollection.rawQuery(q);
    // the polygons dont overlap, expect true
    expect(r['Documents'][0]['\$1']['valid'], isTrue);
  });

  test('Check spatial dataset - MultiPolygon (complement)', () async {
    Query q;
    dynamic r;

    q = Query(
      'SELECT ST_ISVALIDDETAILED(@multi)',
      partition: CosmosDbPartition.all,
      params: {
        '@multi': MultiPolygon()
          ..addAll([
            boisDeBoulogneArea.invert(),
            boisDeVincennesArea.invert(),
          ])
      },
    );
    r = await spatialCollection.rawQuery(q);
    // expect false because inversed polygons overlap
    expect(r['Documents'][0]['\$1']['valid'], isFalse);
  });

  test('Query spatial document', () async {
    var query = Query('SELECT * FROM doc', partition: CosmosDbPartition.all);
    final res0 = await spatialCollection.query<TestSpatialDocumentPoint>(query);
    expect(query.continuation, isEmpty);
    expect(res0.length, equals(2));

    query = Query('SELECT * FROM doc WHERE ST_WITHIN(doc.p, @area)',
        params: {'@area': parisArea}, partition: CosmosDbPartition.all);

    final res1 = await spatialCollection.query<TestSpatialDocumentPoint>(query);
    expect(query.continuation, isEmpty);
    expect(res1.length, equals(1));
    expect(res1.first.id, equals('flt'));

    query = Query('SELECT * FROM doc WHERE ST_WITHIN(doc.p, @area)',
        params: {'@area': parisArea.invert()},
        partition: CosmosDbPartition.all);

    final res2 = await spatialCollection.query<TestSpatialDocumentPoint>(query);
    expect(query.continuation, isEmpty);
    expect(res2.length, equals(1));
    expect(res2.first.id, equals('bbn'));
  });

  test('Polygon with a hole', () async {
    final outer = LineString();
    outer.addAll([
      Point.geometry(-2, -2),
      Point.geometry(2, -2),
      Point.geometry(2, 2),
      Point.geometry(-2, 2),
    ]);

    final inner = LineString();
    inner.addAll([
      Point.geometry(-1, -1),
      Point.geometry(-1, 1),
      Point.geometry(1, 1),
      Point.geometry(1, -1),
    ]);

    final punched = Polygon()..addAll([outer, inner]);

    Query q;
    dynamic r;

    q = Query(
      'SELECT ST_ISVALIDDETAILED(@punched)',
      partition: CosmosDbPartition.all,
      params: {
        '@punched': punched,
      },
    );
    r = await spatialCollection.rawQuery(q);
    expect(r['Documents'][0]['\$1']['valid'], isTrue);

    q = Query(
      'SELECT ST_WITHIN(@point, @punched)',
      partition: CosmosDbPartition.all,
      params: {
        '@point': Point.geometry(0, 0),
        '@punched': punched,
      },
    );
    r = await spatialCollection.rawQuery(q);
    expect(r['Documents'][0]['\$1'], isFalse);

    q = Query(
      'SELECT ST_WITHIN(@point, @punched)',
      partition: CosmosDbPartition.all,
      params: {
        '@point': Point.geometry(0.5, 0.5),
        '@punched': punched,
      },
    );
    r = await spatialCollection.rawQuery(q);
    expect(r['Documents'][0]['\$1'], isFalse);

    q = Query(
      'SELECT ST_WITHIN(@point, @punched)',
      partition: CosmosDbPartition.all,
      params: {
        '@point': Point.geometry(1.5, 1.5),
        '@punched': punched,
      },
    );
    r = await spatialCollection.rawQuery(q);
    expect(r['Documents'][0]['\$1'], isTrue);

    q = Query(
      'SELECT ST_WITHIN(@point, @punched)',
      partition: CosmosDbPartition.all,
      params: {
        '@point': Point.geometry(2.5, 2.5),
        '@punched': punched,
      },
    );
    r = await spatialCollection.rawQuery(q);
    expect(r['Documents'][0]['\$1'], isFalse);
  });
}
