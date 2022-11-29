import 'package:azure_cosmosdb/src/indexing/index_path.dart';
import 'package:azure_cosmosdb/src/indexing/indexing_policy.dart';
import 'package:test/test.dart';

import 'package:azure_cosmosdb/azure_cosmosdb.dart' as cosmos_db;
import 'package:azure_cosmosdb/src/impl/_extensions.dart';

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
  final collName1 = 'test_1';
  final collName2 = 'test_2';
  final idxCollName3 = 'idx_test_3';

  final collNames = {collName1, collName2, idxCollName3};

  late cosmos_db.Database database;

  setUpAll(() async {
    database = await cosmosDB.databases
        .create('test_${DateTime.now().millisecondsSinceEpoch}');
  });

  tearDownAll(() async {
    await cosmosDB.databases.delete(database);
  });

  test('List collections before creation', () async {
    final list = await database.collections.list();
    expect(list.where((c) => collNames.contains(c.id)), isEmpty);
  });

  test('Open a non-existing collection fails', () async {
    await expectLater(
      database.collections.open(collName1),
      throwsA(isA<cosmos_db.NotFoundException>()),
    );
    await expectLater(
      database.collections.open(collName2),
      throwsA(isA<cosmos_db.NotFoundException>()),
    );
  });

  test('Delete a non-existing collection fails when throwOnNotFound is true',
      () async {
    final collection = cosmos_db.Collection(database, collName1);
    expect(collection.exists, isNull);
    await expectLater(
      database.collections.delete(collection, throwOnNotFound: true),
      throwsA(isA<cosmos_db.NotFoundException>()),
    );
  });

  test(
      'Delete a non-existing collection succeeds when throwOnNotFound is false',
      () async {
    final collection = cosmos_db.Collection(database, collName1);
    expect(collection.exists, isNull);
    await database.collections.delete(collection, throwOnNotFound: false);
    expect(collection.exists, isFalse);
  });

  test('Create collection with openOrCreate()', () async {
    final collection = await database.collections
        .openOrCreate(collName1, partitionKeys: ['/id']);
    expect(collection, isNotNull);
    expect(collection.exists, isTrue);
  });

  test('Create collection with openOrCreate() and index policy', () async {
    final indexingPolicy = IndexingPolicy();
    indexingPolicy.excludedPaths.add(IndexPath('/*'));
    indexingPolicy.includedPaths.add(IndexPath('/gid/?'));
    final collection = await database.collections.openOrCreate(idxCollName3,
        partitionKeys: ['/gid'], indexingPolicy: indexingPolicy);
    expect(collection, isNotNull);
    expect(collection.exists, isTrue);
  });

  test('Open collection with openOrCreate()', () async {
    final collection = await database.collections.openOrCreate(collName1);
    expect(collection, isNotNull);
    expect(collection.exists, isTrue);
  });

  test('Create collection with create() fails', () async {
    await expectLater(
      database.collections.create(collName1, partitionKeys: ['/id']),
      throwsA(isA<cosmos_db.ConflictException>()),
    );
  });

  test('List collections after creation', () async {
    final list = await database.collections.list();
    final collection = list.singleOrDefault((coll) => coll.id == collName1);
    expect(collection, isNotNull);
    expect(collection?.exists, isTrue);
  });

  test('Delete collection', () async {
    final collection = await database.collections.openOrCreate(collName1);
    expect(collection.exists, isTrue);
    await database.collections.delete(collection);
    expect(collection.exists, isFalse);
  });

  test('List collections after deletion', () async {
    final list = await database.collections.list();
    final collection = list.singleOrDefault((coll) => coll.id == collName1);
    expect(collection, isNull);
  });
}
