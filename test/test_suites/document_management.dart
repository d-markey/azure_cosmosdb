import 'dart:math';

import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';
import 'package:azure_cosmosdb/src/_internal/_linq_extensions.dart';
import 'package:test/test.dart';

import '../classes/test_document.dart';
import '../classes/test_document_custom_pk.dart';
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
  late final CosmosDbCollection collectionWithPK;

  setUpAll(() async {
    database = await cosmosDB.databases.create(getTempName());
    collection = await database.collections.create(
      'items',
      partitionKey: '/id',
    );
    collection.registerBuilder<TestDocument>(TestDocument.fromJson);
    collectionWithPK = await database.collections.create(
      'items_custom_pk',
      partitionKey: '/pk',
    );
    collectionWithPK
        .registerBuilder<TestDocumentWithPK>(TestDocumentWithPK.fromJson);
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

  test('Add documents - custom PK', () async {
    await collectionWithPK
        .add(TestDocumentWithPK('1', 'triplet', 'TEST #1', [1, 2, 3]));
    await collectionWithPK
        .add(TestDocumentWithPK('2', 'triplet', 'TEST #2', [2, 3, 5]));
    await collectionWithPK
        .add(TestDocumentWithPK('1', 'couple', 'TEST #2', [7, 9]));

    final list = await collectionWithPK.list<TestDocumentWithPK>();
    expect(list.length, equals(3));
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

  test('Upsert a non-existing document - custom PK', () async {
    final before = await collectionWithPK.list<TestDocumentWithPK>();
    final check = before.firstOrDefault((d) => d.id == '3');
    expect(check, isNull);

    await collectionWithPK.upsert(
        TestDocumentWithPK('3', 'couple', 'UPSERT/CREATE TEST #3', [1, 2]));

    final after = await collectionWithPK.list<TestDocumentWithPK>();
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

  test('Upsert an existing document - custom PK', () async {
    final before = await collectionWithPK.list<TestDocument>();
    final check = before.firstOrDefault((d) => d.id == '2');
    expect(check, isNotNull);

    await collectionWithPK.upsert(TestDocumentWithPK(
        '2', 'triplet', 'UPSERT/REPLACE TEST #2', [7, 11, 13]));

    final after = await collectionWithPK.list<TestDocument>();
    expect(after.length, equals(before.length));

    final doc = after.firstOrDefault((d) => d.id == '2');
    expect(doc, isNotNull);
    expect(doc!.label, equals('UPSERT/REPLACE TEST #2'));
  });

  test('Replace a document', () async {
    final before = await collection.list<TestDocument>();
    var doc = before.skip(Random().nextInt(before.length - 1)).first;
    doc = (await collection.get(doc))!;
    doc.label = '${doc.label} (REPLACED)';
    await collection.replace(doc);
    final after = await collection.list<TestDocument>();
    expect(after.length, equals(before.length));
    expect(after.where((d) => d.id == doc.id), isNotEmpty);
    expect(
        after.where((d) => d.id == doc.id).first.label, endsWith('(REPLACED)'));
  });

  test('Patch a document', () async {
    final before = await collection.list<TestDocument>();
    final doc = before.skip(Random().nextInt(before.length - 1)).first;
    expect(doc.props['counter'], isNull);

    var patch = Patch()
      ..set('/l', '${doc.label} (PATCHED)')
      ..add('/counter', 2)
      ..increment('/counter');
    final patched = await collection.patch(doc, patch);
    final after = await collection.list<TestDocument>();
    expect(after.length, equals(before.length));
    expect(after.where((d) => d.id == doc.id), isNotEmpty);
    expect(patched.id, equals(doc.id));
    expect(patched.label, endsWith('(PATCHED)'));
    expect(patched.props['counter'], equals(2 + 1));
  });

  test('Patch a document - custom PK', () async {
    final before = await collectionWithPK.list<TestDocumentWithPK>();
    final doc = before.skip(Random().nextInt(before.length - 1)).first;
    expect(doc.props['counter'], isNull);

    var patch = Patch()
      ..set('/l', '${doc.label} (PATCHED)')
      ..add('/counter', 3)
      ..increment('/counter', 7);
    var patched = await collectionWithPK.patch(doc, patch);
    expect(patched.partitionKey, equals(doc.partitionKey));
    expect(patched.label, endsWith('(PATCHED)'));
    expect(patched.props['counter'], equals(3 + 7));

    patch = Patch()..decrement('/counter', 5);
    patched = await collectionWithPK.patch(doc, patch);
    expect(patched.partitionKey, equals(doc.partitionKey));
    expect(patched.label, endsWith('(PATCHED)'));
    expect(patched.props['counter'], equals(3 + 7 - 5));

    patch = Patch()
      ..replace('/counter', -1)
      ..replace('/l', 'OVERWRITTEN');
    patched = await collectionWithPK.patch(doc, patch);
    expect(patched.partitionKey, equals(doc.partitionKey));
    expect(patched.label, equals('OVERWRITTEN'));
    expect(patched.props['counter'], equals(-1));

    patch = Patch()
      ..remove('/counter')
      ..setCondition(
          'from c where c.counter = @neg and CONTAINS(c.l, \'PATCHED\')')
      ..withParam('@neg', -1);
    await expectLater(collectionWithPK.patch(doc, patch),
        throwsA(isA<PreconditionFailureException>()));

    patch = Patch()
      ..remove('/counter')
      ..setCondition(
          'from c where c.counter = @neg and CONTAINS(c.l, \'OVER\')')
      ..withParam('@neg', -1);
    patched = await collectionWithPK.patch(doc, patch);
    expect(patched.partitionKey, equals(doc.partitionKey));
    expect(patched.label, equals('OVERWRITTEN'));
    expect(patched.props['counter'], isNull);

    final after = await collectionWithPK.list<TestDocumentWithPK>();
    expect(after.length, equals(before.length));
    expect(after.where((d) => d.partitionKey == doc.partitionKey), isNotEmpty);
  });

  test('Replace a document - etag mismatch', () async {
    final before = await collection.list<TestDocument>();
    final doc = before.skip(Random().nextInt(before.length - 1)).first;
    final label = doc.label;
    doc.label = '$label (MUST NOT BE REPLACED)';
    doc.setEtag({'_etag': 'dummy'});
    await expectLater(
        collection.replace(doc), throwsA(isA<PreconditionFailureException>()));
    final after = await collection.list<TestDocument>();
    expect(after.length, equals(before.length));
    expect(after.where((d) => d.id == doc.id), isNotEmpty);
    expect(after.where((d) => d.label.endsWith('(MUST NOT BE REPLACED)')),
        isEmpty);
    expect(after.where((d) => d.id == doc.id).first.label, equals(label));
  });

  test('Replace a document - custom PK + etag mismatch', () async {
    final before = await collectionWithPK.list<TestDocumentWithPK>();
    final doc = before.skip(Random().nextInt(before.length - 1)).first;
    final label = doc.label;
    doc.label = '$label (MUST NOT BE REPLACED)';
    doc.setEtag({'_etag': 'dummy'});
    await expectLater(collectionWithPK.replace(doc),
        throwsA(isA<PreconditionFailureException>()));
    final after = await collectionWithPK.list<TestDocumentWithPK>();
    expect(after.length, equals(before.length));
    expect(after.where((d) => d.id == doc.id), isNotEmpty);
    expect(after.where((d) => d.label.endsWith('(MUST NOT BE REPLACED)')),
        isEmpty);
    expect(after.where((d) => d.partitionKey == doc.partitionKey).first.label,
        equals(label));
  });

  test('Trying to load documents with no associated builder must fail',
      () async {
    await expectLater(collection.list<TestDocumentWithoutBuilder>(),
        throwsA(isA<UnknownDocumentTypeException>()));
  });

  test('Delete document', () async {
    final before = await collection.list<TestDocument>();

    var doc = before.firstWhere((d) => d.id == '1');
    expect(await collection.delete('', document: doc), isTrue);

    final after = await collection.list<TestDocument>();
    expect(after.length, equals(before.length - 1));
    expect(after.every((d) => d.etag.isNotEmpty), isTrue);

    expect(await collection.delete(doc.id), isTrue);

    await expectLater(
      collection.delete(doc.id, throwOnNotFound: true),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('Delete document - custom PK', () async {
    final before = await collectionWithPK.list<TestDocumentWithPK>();

    var doc = before.firstWhere((d) => d.id == '1');
    expect(await collectionWithPK.delete('', document: doc), isTrue);

    final after = await collectionWithPK.list<TestDocumentWithPK>();
    expect(after.length, equals(before.length - 1));
    expect(after.every((d) => d.etag.isNotEmpty), isTrue);

    expect(await collectionWithPK.delete('', document: doc), isTrue);

    await expectLater(
      collectionWithPK.delete('', document: doc, throwOnNotFound: true),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('Delete document - etag mismatch', () async {
    final before = await collection.list<TestDocument>();

    var doc = before.first;
    doc.setEtag({'_etag': 'dummy'});
    await expectLater(collection.delete('', document: doc),
        throwsA(isA<PreconditionFailureException>()));

    final after = await collection.list<TestDocument>();
    expect(after.length, equals(before.length));
  });

  test('Delete document - custom PK + etag mismatch', () async {
    final before = await collectionWithPK.list<TestDocumentWithPK>();

    var doc = before.first;
    doc.setEtag({'_etag': 'dummy'});
    await expectLater(collectionWithPK.delete('', document: doc),
        throwsA(isA<PreconditionFailureException>()));

    final after = await collectionWithPK.list<TestDocumentWithPK>();
    expect(after.length, equals(before.length));
  });

  test('Throttling', () async {
    final delay = Duration(milliseconds: 200);

    expect(cosmosDB.dbgHttpClient?.forceThrottleDelay, isNull);
    var start = DateTime.now().toUtc();
    final before = await collection.list<TestDocument>();
    var elapsed = DateTime.now().toUtc().difference(start);
    expect(elapsed.inMilliseconds, lessThan(delay.inMilliseconds));

    cosmosDB.dbgHttpClient?.forceThrottleDelay = delay;

    expect(cosmosDB.dbgHttpClient?.forceThrottleDelay, isNotNull);
    start = DateTime.now().toUtc();
    final after = await collection.list<TestDocument>();
    elapsed = DateTime.now().toUtc().difference(start);
    expect(elapsed.inMilliseconds, greaterThanOrEqualTo(delay.inMilliseconds));

    expect(cosmosDB.dbgHttpClient?.forceThrottleDelay, isNull);
    expect(after.length, equals(before.length));
  });
}
