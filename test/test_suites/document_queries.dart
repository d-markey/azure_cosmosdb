import 'package:http/http.dart';
import 'package:test/test.dart';

import 'package:azure_cosmosdb/azure_cosmosdb.dart' as cosmos_db;

import '../classes/test_document.dart';
import '../classes/cosmosdb_test_instance.dart';

void main() async {
  allowSelfSignedCertificates();
  final httpClient = cosmos_db.DebugHttpClient();
  final cosmosDB = getTestInstance(httpClient);

  try {
    await cosmosDB.databases.list();
  } catch (e) {
    test('! COSMOS DB IS OFFLINE - TESTS HAVE BEEN DISABLED', () {
      print('Exception: $e');
    });
    return;
  }

  run(cosmosDB, httpClient);
}

void run(cosmos_db.Instance cosmosDB, Client httpCLient) {
  late final cosmos_db.Database database;
  late final cosmos_db.Collection collection;

  setUpAll(() async {
    database = await cosmosDB.databases
        .create('test_${DateTime.now().millisecondsSinceEpoch}');
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
    final query = cosmos_db.Query('SELECT * FROM doc WHERE doc.id=@id');

    query.withParam('@id', '1');
    query.onPartition('1');
    var res = await collection.query<TestDocument>(query);
    expect(res.length, equals(1));
    expect(res.first.id, equals('1'));

    query.onPartition('2');
    res = await collection.query<TestDocument>(query);
    expect(res, isEmpty);

    query.withParam('@id', '2');
    res = await collection.query<TestDocument>(query);
    expect(res.length, equals(1));
    expect(res.first.id, equals('2'));
  });

  test('Query multiple documents', () async {
    // /!\ NOTE: TestDocuments serialize as { 'id': id , 'l': label, 'd': data}
    // /!\ NOTE: to match the label, the query must use 'doc.l'
    final query = cosmos_db.Query(
        'SELECT * FROM doc WHERE CONTAINS(doc.l, @text)',
        params: {'@text': 'PRIME'},
        partition: cosmos_db.Partition.all);
    final res = await collection.query<TestDocument>(query);
    expect(res.length, equals(2));
    expect(query.continuation, isEmpty);
  });

  test('Query multiple documents with paging', () async {
    final query = cosmos_db.Query(
        'SELECT * FROM doc WHERE CONTAINS(doc.l, @text)',
        params: {'@text': 'PRIME'},
        partition: cosmos_db.Partition.all);

    query.maxCount = 1;

    final res1 = await collection.query<TestDocument>(query);
    expect(query.continuation, isNotEmpty);
    expect(res1.length, equals(1));

    final res2 = await collection.query<TestDocument>(query);
    expect(query.continuation, isEmpty);
    expect(res2.length, equals(1));

    expect(res1.first.id == res2.first.id, isFalse);
  });
}
