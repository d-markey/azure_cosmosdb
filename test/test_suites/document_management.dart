import 'dart:math';

import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';
import 'package:azure_cosmosdb/src/_internal/_linq_extensions.dart';
import 'package:test/test.dart';

import '../classes/test_document.dart';
import '../classes/test_document_without_builder.dart';
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
    database = await cosmosDB.databases.create(getTempName());
    collection = await database.collections.create(
      'items',
      partitionKeys: ['/id'],
    );
    collection.registerBuilder<TestDocument>(TestDocument.fromJson);
  });

  tearDownAll(() async {
    await cosmosDB.databases.delete(database);
  });

  test('List documents before creation', () async {
    expect(await collection.list<TestDocument>(), isEmpty);

    final query = Query(
      'SELECT * FROM docs WHERE docs.id=@id',
      params: {'@id': '1'},
    );
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

  test('Upsert a non-existing document', () async {
    final before = await collection.list<TestDocument>();
    final check = before.firstOrDefault((d) => d.id == '3');
    expect(check, isNull);

    await collection
        .upsert(TestDocument('3', 'UPSERT/CREATE TEST #3', [7, 11, 13]));

    final after = await collection.list<TestDocument>();
    expect(after.length, equals(before.length + 1));

    final doc = after.firstOrDefault((d) => d.id == '3');
    expect(doc, isNotNull);
    expect(doc!.label, equals('UPSERT/CREATE TEST #3'));
  });

  test('Upsert an existing document', () async {
    final before = await collection.list<TestDocument>();
    final check = before.firstOrDefault((d) => d.id == '2');
    expect(check, isNotNull);

    await collection
        .upsert(TestDocument('2', 'UPSERT/REPLACE TEST #2', [7, 11, 13]));

    final after = await collection.list<TestDocument>();
    expect(after.length, equals(before.length));

    final doc = after.firstOrDefault((d) => d.id == '2');
    expect(doc, isNotNull);
    expect(doc!.label, equals('UPSERT/REPLACE TEST #2'));
  });

  test('Replace a document', () async {
    final before = await collection.list<TestDocument>();
    final doc = before.skip(Random().nextInt(before.length - 1)).first;
    doc.label = '${doc.label} (REPLACED)';
    await collection.replace(doc);
    final after = await collection.list<TestDocument>();
    expect(after.length, equals(before.length));
    expect(after.where((d) => d.id == doc.id), isNotEmpty);
    expect(
        after.where((d) => d.id == doc.id).first.label, endsWith('(REPLACED)'));
  });

  test('Trying to load documents with no associated builder must fail',
      () async {
    await expectLater(collection.list<TestDocumentWithoutBuilder>(),
        throwsA(isA<UnknownDocumentTypeException>()));
  });

  test('Delete document', () async {
    final before = await collection.list<TestDocument>();

    expect(await collection.delete('1'), isTrue);

    final after = await collection.list<TestDocument>();
    expect(after.length, equals(before.length - 1));
    expect(after.every((d) => d.etag.isNotEmpty), isTrue);

    expect(await collection.delete('1'), isTrue);

    await expectLater(
      collection.delete('1', throwOnNotFound: true),
      throwsA(isA<NotFoundException>()),
    );
  });
}
