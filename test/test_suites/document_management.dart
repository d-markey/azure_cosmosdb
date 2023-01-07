import 'dart:math';

import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';
import 'package:azure_cosmosdb/src/_internal/_linq_extensions.dart';
import 'package:test/test.dart';

import '../classes/test_document.dart';
import '../classes/test_document_synthetic_pk.dart';
import '../classes/test_document_multi_pk.dart';
import '../classes/test_document_without_builder.dart';
import '../classes/test_helpers.dart';

void main() async {
  final cosmosDB = await getTestInstance(preview: true);
  if (cosmosDB != null) {
    run(cosmosDB);
  }
}

void run(CosmosDbServer cosmosDB) {
  late final CosmosDbDatabase database;
  late final CosmosDbContainer container;
  late final CosmosDbContainer containerSyntheticPK;
  late final CosmosDbContainer containerMultiPK;

  setUpAll(() async {
    database = await cosmosDB.databases.create(getTempName());
    container = await database.containers.create(
      'items',
      partitionKey: PartitionKeySpec.id,
    );
    container.registerBuilder<TestDocument>(TestDocument.fromJson);
    containerSyntheticPK = await database.containers.create(
      'items_synthetic_pk',
      partitionKey: PartitionKeySpec('/pk'),
    );
    containerSyntheticPK.registerBuilder<TestDocumentSyntheticPK>(
        TestDocumentSyntheticPK.fromJson);
    if (cosmosDB.features.multiHash) {
      containerMultiPK = await database.containers.create(
        'items_multi_pk',
        partitionKey: PartitionKeySpec.multi(['/tid', '/uid']),
      );
      containerSyntheticPK
          .registerBuilder<TestDocumentMultiPK>(TestDocumentMultiPK.fromJson);
    }
  });

  tearDownAll(() async {
    await cosmosDB.databases.delete(database);
  });

  test('List documents before creation', () async {
    expect(await container.list<TestDocument>(), isEmpty);

    final query = Query(
      'SELECT * FROM docs WHERE docs.id=@id',
      params: {'@id': '1'},
    );
    query.onPartition(PartitionKey('1'));
    expect(await container.query<TestDocument>(query), isEmpty);

    query.withParam('@id', '2');
    query.crossPartition();
    expect(await container.query<TestDocument>(query), isEmpty);
  });

  test('Add documents', () async {
    await container.add(TestDocument('1', 'TEST #1', [1, 2, 3]));
    await container.add(TestDocument('2', 'TEST #2', [2, 3, 5]));

    final list = await container.list<TestDocument>();
    expect(list.length, equals(2));
    expect(list.every((d) => d.etag.isNotEmpty), isTrue);
  });

  test('Add documents - synthetic PK', () async {
    await containerSyntheticPK
        .add(TestDocumentSyntheticPK('1', 'triplet', 'TEST #1', [1, 2, 3]));
    await containerSyntheticPK
        .add(TestDocumentSyntheticPK('2', 'triplet', 'TEST #2', [2, 3, 5]));
    await containerSyntheticPK
        .add(TestDocumentSyntheticPK('1', 'couple', 'TEST #2', [7, 9]));

    final list = await containerSyntheticPK.list<TestDocumentSyntheticPK>();
    expect(list.length, equals(3));
    expect(list.every((d) => d.etag.isNotEmpty), isTrue);
  });

  test('Add documents - multi PK', () async {
    await containerMultiPK
        .add(TestDocumentMultiPK('001', 'tenant-1', 'user-1', 'T1 > U1: 001'));
    await containerMultiPK
        .add(TestDocumentMultiPK('002', 'tenant-1', 'user-2', 'T1 > U2: 002'));
    await containerMultiPK
        .add(TestDocumentMultiPK('003', 'tenant-2', 'user-1', 'T2 > U1: 003'));

    final list = await containerMultiPK.list<TestDocumentMultiPK>();
    expect(list.length, equals(3));
  }, skip: !cosmosDB.features.multiHash);

  test('Upsert a non-existing document', () async {
    final before = await container.list<TestDocument>();
    final check = before.firstOrDefault((d) => d.id == '3');
    expect(check, isNull);

    await container
        .upsert(TestDocument('3', 'UPSERT/CREATE TEST #3', [7, 11, 13]));

    final after = await container.list<TestDocument>();
    expect(after.length, equals(before.length + 1));

    final doc = after.firstOrDefault((d) => d.id == '3');
    expect(doc, isNotNull);
    expect(doc!.label, equals('UPSERT/CREATE TEST #3'));
  });

  test('Upsert a non-existing document - synthetic PK', () async {
    final before = await containerSyntheticPK.list<TestDocumentSyntheticPK>();
    final check = before.firstOrDefault((d) => d.id == '3');
    expect(check, isNull);

    await containerSyntheticPK.upsert(TestDocumentSyntheticPK(
        '3', 'couple', 'UPSERT/CREATE TEST #3', [1, 2]));

    final after = await containerSyntheticPK.list<TestDocumentSyntheticPK>();
    expect(after.length, equals(before.length + 1));

    final doc = after.firstOrDefault((d) => d.id == '3');
    expect(doc, isNotNull);
    expect(doc!.label, equals('UPSERT/CREATE TEST #3'));
  });

  test('Upsert a non-existing document - multi PK', () async {
    final before = await containerMultiPK.list<TestDocumentMultiPK>();
    final check = before.firstOrDefault((d) => d.id == '004');
    expect(check, isNull);

    await containerMultiPK.upsert(
        TestDocumentMultiPK('004', 'tenant-1', 'user-2', 'T1 > U2: 004'));

    final after = await containerMultiPK.list<TestDocumentMultiPK>();
    expect(after.length, equals(before.length + 1));

    final doc = after.firstOrDefault((d) => d.id == '004');
    expect(doc, isNotNull);
    expect(doc!.label, equals('T1 > U2: 004'));
  }, skip: !cosmosDB.features.multiHash);

  test('Upsert an existing document', () async {
    final before = await container.list<TestDocument>();
    final check = before.firstOrDefault((d) => d.id == '2');
    expect(check, isNotNull);

    await container
        .upsert(TestDocument('2', 'UPSERT/REPLACE TEST #2', [7, 11, 13]));

    final after = await container.list<TestDocument>();
    expect(after.length, equals(before.length));

    final doc = after.firstOrDefault((d) => d.id == '2');
    expect(doc, isNotNull);
    expect(doc!.label, equals('UPSERT/REPLACE TEST #2'));
  });

  test('Upsert an existing document - synthetic PK', () async {
    final before = await containerSyntheticPK.list<TestDocument>();
    final check = before.firstOrDefault((d) => d.id == '2');
    expect(check, isNotNull);

    await containerSyntheticPK.upsert(TestDocumentSyntheticPK(
        '2', 'triplet', 'UPSERT/REPLACE TEST #2', [7, 11, 13]));

    final after = await containerSyntheticPK.list<TestDocument>();
    expect(after.length, equals(before.length));

    final doc = after.firstOrDefault((d) => d.id == '2');
    expect(doc, isNotNull);
    expect(doc!.label, equals('UPSERT/REPLACE TEST #2'));
  });

  test('Upsert an existing document - multi PK', () async {
    final before = await containerMultiPK.list<TestDocumentMultiPK>();
    final check = before.firstOrDefault((d) => d.id == '002');
    expect(check, isNotNull);

    await containerMultiPK.upsert(TestDocumentMultiPK(
        '002', 'tenant-1', 'user-2', 'T1 > U2: 002 (updated)'));

    final after = await containerMultiPK.list<TestDocumentMultiPK>();
    expect(after.length, equals(before.length));

    final doc = after.firstOrDefault((d) => d.id == '002');
    expect(doc, isNotNull);
    expect(doc!.label, equals('T1 > U2: 002 (updated)'));
  }, skip: !cosmosDB.features.multiHash);

  test('Replace a document', () async {
    final before = await container.list<TestDocument>();
    var doc = before.skip(Random().nextInt(before.length - 1)).first;
    doc = (await container.get(doc))!;
    doc.label = '${doc.label} (REPLACED)';
    await container.replace(doc);
    final after = await container.list<TestDocument>();
    expect(after.length, equals(before.length));
    expect(after.where((d) => d.id == doc.id), isNotEmpty);
    expect(
        after.where((d) => d.id == doc.id).first.label, endsWith('(REPLACED)'));
  });

  test('Replace a document - multi PK', () async {
    final before = await containerMultiPK.list<TestDocumentMultiPK>();
    var doc = before.skip(Random().nextInt(before.length - 1)).first;
    doc = (await containerMultiPK.get(doc))!;
    doc.label = '${doc.label} (REPLACED)';
    await containerMultiPK.replace(doc);
    final after = await containerMultiPK.list<TestDocumentMultiPK>();
    expect(after.length, equals(before.length));
    expect(after.where((d) => d.id == doc.id), isNotEmpty);
    expect(
        after.where((d) => d.id == doc.id).first.label, endsWith('(REPLACED)'));
  }, skip: !cosmosDB.features.multiHash);

  test('Patch a document', () async {
    final before = await container.list<TestDocument>();
    final doc = before.skip(Random().nextInt(before.length - 1)).first;
    expect(doc.props['counter'], isNull);

    var patch = Patch()
      ..set('/l', '${doc.label} (PATCHED)')
      ..add('/counter', 2)
      ..increment('/counter');
    final patched = await container.patch(doc, patch);
    final after = await container.list<TestDocument>();
    expect(after.length, equals(before.length));
    expect(after.where((d) => d.id == doc.id), isNotEmpty);
    expect(patched.id, equals(doc.id));
    expect(patched.label, endsWith('(PATCHED)'));
    expect(patched.props['counter'], equals(2 + 1));
  });

  test('Patch a document - synthetic PK', () async {
    final before = await containerSyntheticPK.list<TestDocumentSyntheticPK>();
    final doc = before.skip(Random().nextInt(before.length - 1)).first;
    expect(doc.props['counter'], isNull);

    var patch = Patch()
      ..set('/l', '${doc.label} (PATCHED)')
      ..add('/counter', 3)
      ..increment('/counter', 7);
    var patched = await containerSyntheticPK.patch(doc, patch);
    expect(patched.keys, equals(doc.keys));
    expect(patched.label, endsWith('(PATCHED)'));
    expect(patched.props['counter'], equals(3 + 7));

    patch = Patch()..decrement('/counter', 5);
    patched = await containerSyntheticPK.patch(doc, patch);
    expect(patched.keys, equals(doc.keys));
    expect(patched.label, endsWith('(PATCHED)'));
    expect(patched.props['counter'], equals(3 + 7 - 5));

    patch = Patch()
      ..replace('/counter', -1)
      ..replace('/l', 'OVERWRITTEN');
    patched = await containerSyntheticPK.patch(doc, patch);
    expect(patched.keys, equals(doc.keys));
    expect(patched.label, equals('OVERWRITTEN'));
    expect(patched.props['counter'], equals(-1));

    patch = Patch()
      ..remove('/counter')
      ..setCondition(
          'from c where c.counter = @neg and CONTAINS(c.l, \'PATCHED\')')
      ..withParam('@neg', -1);
    await expectLater(containerSyntheticPK.patch(doc, patch),
        throwsA(isA<PreconditionFailureException>()));

    patch = Patch()
      ..remove('/counter')
      ..setCondition(
          'from c where c.counter = @neg and CONTAINS(c.l, \'OVER\')')
      ..withParam('@neg', -1);
    patched = await containerSyntheticPK.patch(doc, patch);
    expect(patched.keys, equals(doc.keys));
    expect(patched.label, equals('OVERWRITTEN'));
    expect(patched.props['counter'], isNull);

    final after = await containerSyntheticPK.list<TestDocumentSyntheticPK>();
    expect(after.length, equals(before.length));
    expect(after.where((d) => d.keys.first == doc.keys.first), isNotEmpty);
  });

  test('Replace a document - etag mismatch', () async {
    final before = await container.list<TestDocument>();
    final doc = before.skip(Random().nextInt(before.length - 1)).first;
    final label = doc.label;
    doc.label = '$label (MUST NOT BE REPLACED)';
    doc.setEtag({'_etag': 'dummy'});
    await expectLater(
        container.replace(doc), throwsA(isA<PreconditionFailureException>()));
    final after = await container.list<TestDocument>();
    expect(after.length, equals(before.length));
    expect(after.where((d) => d.id == doc.id), isNotEmpty);
    expect(after.where((d) => d.label.endsWith('(MUST NOT BE REPLACED)')),
        isEmpty);
    expect(after.where((d) => d.id == doc.id).first.label, equals(label));
  });

  test('Replace a document - synthetic PK + etag mismatch', () async {
    final before = await containerSyntheticPK.list<TestDocumentSyntheticPK>();
    final doc = before.skip(Random().nextInt(before.length - 1)).first;
    final label = doc.label;
    doc.label = '$label (MUST NOT BE REPLACED)';
    doc.setEtag({'_etag': 'dummy'});
    await expectLater(containerSyntheticPK.replace(doc),
        throwsA(isA<PreconditionFailureException>()));
    final after = await containerSyntheticPK.list<TestDocumentSyntheticPK>();
    expect(after.length, equals(before.length));
    expect(after.where((d) => d.id == doc.id), isNotEmpty);
    expect(after.where((d) => d.label.endsWith('(MUST NOT BE REPLACED)')),
        isEmpty);
    expect(after.where((d) => d.keys.first == doc.keys.first).first.label,
        equals(label));
  });

  test('Trying to load documents with no associated builder must fail',
      () async {
    await expectLater(container.list<TestDocumentWithoutBuilder>(),
        throwsA(isA<UnknownDocumentTypeException>()));
  });

  test('Delete document', () async {
    final before = await container.list<TestDocument>();

    var doc = before.firstWhere((d) => d.id == '1');
    expect(await container.delete(document: doc), isTrue);

    final after = await container.list<TestDocument>();
    expect(after.length, equals(before.length - 1));
    expect(after.every((d) => d.etag.isNotEmpty), isTrue);

    expect(await container.delete(id: doc.id), isTrue);

    await expectLater(
      container.delete(id: doc.id, throwOnNotFound: true),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('Delete document - synthetic PK', () async {
    final before = await containerSyntheticPK.list<TestDocumentSyntheticPK>();

    var doc = before.firstWhere((d) => d.id == '1');
    expect(await containerSyntheticPK.delete(document: doc), isTrue);

    final after = await containerSyntheticPK.list<TestDocumentSyntheticPK>();
    expect(after.length, equals(before.length - 1));
    expect(after.every((d) => d.etag.isNotEmpty), isTrue);

    expect(await containerSyntheticPK.delete(document: doc), isTrue);

    await expectLater(
      containerSyntheticPK.delete(document: doc, throwOnNotFound: true),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('Delete document - multi PK', () async {
    final before = await containerMultiPK.list<TestDocumentMultiPK>();

    var doc = before.firstWhere((d) => d.id == '003');
    expect(await containerMultiPK.delete(document: doc), isTrue);

    final after = await containerMultiPK.list<TestDocumentMultiPK>();
    expect(after.length, equals(before.length - 1));

    expect(await containerMultiPK.delete(document: doc), isTrue);

    await expectLater(
      containerMultiPK.delete(document: doc, throwOnNotFound: true),
      throwsA(isA<NotFoundException>()),
    );
  }, skip: !cosmosDB.features.multiHash);

  test('Delete document - etag mismatch', () async {
    final before = await container.list<TestDocument>();

    var doc = before.first;
    doc.setEtag({'_etag': 'dummy'});
    await expectLater(container.delete(document: doc),
        throwsA(isA<PreconditionFailureException>()));

    final after = await container.list<TestDocument>();
    expect(after.length, equals(before.length));
  });

  test('Delete document - synthetic PK + etag mismatch', () async {
    final before = await containerSyntheticPK.list<TestDocumentSyntheticPK>();

    var doc = before.first;
    doc.setEtag({'_etag': 'dummy'});
    await expectLater(containerSyntheticPK.delete(document: doc),
        throwsA(isA<PreconditionFailureException>()));

    final after = await containerSyntheticPK.list<TestDocumentSyntheticPK>();
    expect(after.length, equals(before.length));
  });

  test('Throttling', () async {
    final delay = Duration(milliseconds: 200);

    expect(cosmosDB.dbgHttpClient?.forceThrottleDelay, isNull);
    var sw = Stopwatch()..start();
    final before = await container.list<TestDocument>();
    expect(sw.elapsed, lessThan(delay));

    cosmosDB.dbgHttpClient?.forceThrottleDelay = delay;

    expect(cosmosDB.dbgHttpClient?.forceThrottleDelay, isNotNull);
    sw.reset();
    final after = await container.list<TestDocument>();
    expect(sw.elapsed, greaterThanOrEqualTo(delay));

    expect(after.length, equals(before.length));

    expect(cosmosDB.dbgHttpClient?.forceThrottleDelay, isNull);
  });
}
