import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';
import 'package:test/test.dart';

import '../classes/test_document.dart';
import '../classes/test_helpers.dart';

void main() async {
  final cosmosDB = await getTestInstance();
  if (cosmosDB != null) {
    run(cosmosDB);
  }
}

void run(CosmosDbServer cosmosDB) {
  late final CosmosDbDatabase database;
  late final CosmosDbCollection collection;

  setUpAll(() async {
    database = await cosmosDB.databases.create(getTempDbName());
    collection =
        await database.collections.create('items', partitionKeys: ['/id']);
    collection.registerBuilder<TestDocument>(TestDocument.fromJson);
    await collection.add(TestDocument('1', 'PRIME #1', [2, 3, 5]));
    await collection.add(TestDocument('2', 'PRIME #2', [7, 11, 13]));
    await collection.add(TestDocument('3', 'EVEN', [2, 4, 6]));
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
}
