import 'package:test/test.dart';

import 'package:azure_cosmosdb/azure_cosmosdb.dart' as cosmos_db;

import '../classes/test_document.dart';
import '../classes/cosmosdb_test_instance.dart';

void main() async {
  allowSelfSignedCertificates();
  final cosmosDB = getTestInstance(cosmos_db.DebugHttpClient());

  try {
    await cosmosDB.databases.list();
  } catch (e) {
    test('! COSMOS DB IS OFFLINE - TESTS HAVE BEEN DISABLED', () {
      print('Exception: $e');
    });
    return;
  }

  run(cosmosDB);
}

void run(cosmos_db.Instance cosmosDB) {
  late final cosmos_db.Database database;
  late final cosmos_db.Collection collection;

  setUpAll(() async {
    database = await cosmosDB.databases
        .create('test_${DateTime.now().millisecondsSinceEpoch}');
    collection =
        await database.collections.create('items', partitionKeys: ['/id']);
    collection.registerBuilder<TestDocument>(TestDocument.fromJson);
  });

  tearDownAll(() async {
    await cosmosDB.databases.delete(database);
  });

  test('List documents before creation', () async {
    expect(await collection.list<TestDocument>(), isEmpty);

    final query = cosmos_db.Query('SELECT * FROM docs WHERE docs.id=@id',
        params: {'@id': '1'});
    query.onPartition('1');
    expect(await collection.query<TestDocument>(query), isEmpty);

    query.withParam('@id', '2');
    query.crossPartition();
    expect(await collection.query<TestDocument>(query), isEmpty);
  });

  test('Add documents', () async {
    await collection.add(TestDocument('1', 'TEST #1', [1, 2, 3]));
    await collection.add(TestDocument('2', 'TEST #2', [2, 3, 5]));

    final list = await collection.list<TestDocument>();
    expect(list.length, equals(2));
    expect(list.every((d) => d.etag.isNotEmpty), isTrue);
  });

  test('Delete document', () async {
    expect(await collection.delete('1'), isTrue);

    final list = await collection.list<TestDocument>();
    expect(list.length, equals(1));
    expect(list.every((d) => d.etag.isNotEmpty), isTrue);

    expect(await collection.delete('1'), isTrue);

    await expectLater(
      collection.delete('1', throwOnNotFound: true),
      throwsA(isA<cosmos_db.NotFoundException>()),
    );
  });
}
