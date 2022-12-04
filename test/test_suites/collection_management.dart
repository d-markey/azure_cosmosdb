import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';
import 'package:azure_cosmosdb/src/_internal/_extensions.dart';
import 'package:test/test.dart';

import '../classes/test_helpers.dart';

void main() async {
  final cosmosDB = await getTestInstance();
  if (cosmosDB != null) {
    run(cosmosDB);
  }
}

void run(CosmosDbServer cosmosDB) {
  final collName1 = 'test_1';
  final collName2 = 'not_found_2';
  final collName3 = 'idx_test_3';
  final collName4 = 'idx_test_4';
  final collName5 = 'geom_test_5';
  final collName6 = 'geos_test_6';
  final collName7 = 'test_7';

  final collNames = {
    collName1,
    collName2,
    collName3,
    collName4,
    collName5,
    collName6,
    collName7,
  };

  late CosmosDbDatabase database;

  setUpAll(() async {
    database = await cosmosDB.databases.create(getTempDbName());
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
      throwsA(isA<NotFoundException>()),
    );
    await expectLater(
      database.collections.open(collName2),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('Delete a non-existing collection fails when throwOnNotFound is true',
      () async {
    final collection = CosmosDbCollection(database, collName1);
    expect(collection.exists, isNull);
    await expectLater(
      database.collections.delete(collection, throwOnNotFound: true),
      throwsA(isA<NotFoundException>()),
    );
  });

  test(
      'Delete a non-existing collection succeeds when throwOnNotFound is false',
      () async {
    final collection = CosmosDbCollection(database, collName1);
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

  test('Create collection with openOrCreate() and simple indexing policy',
      () async {
    final indexingPolicy = IndexingPolicy();
    indexingPolicy.excludedPaths.add(IndexPath('/*'));
    indexingPolicy.includedPaths.add(IndexPath('/gid/?'));
    final collection = await database.collections.openOrCreate(collName3,
        partitionKeys: ['/gid'], indexingPolicy: indexingPolicy);
    expect(collection, isNotNull);
    expect(collection.exists, isTrue);
  });

  test(
      'Create collection with openOrCreate() and indexing policy with composite index',
      () async {
    final indexingPolicy = IndexingPolicy();
    indexingPolicy.excludedPaths.add(IndexPath('/*'));
    indexingPolicy.includedPaths.add(IndexPath('/gid/?'));
    indexingPolicy.compositeIndexes.add([
      IndexPath('/label', order: IndexOrder.ascending),
      IndexPath('/"due-date"', order: IndexOrder.descending),
    ]);
    final collection = await database.collections.openOrCreate(collName4,
        partitionKeys: ['/gid'], indexingPolicy: indexingPolicy);
    expect(collection, isNotNull);
    expect(collection.exists, isTrue);
  });

  test(
      'Create collection with openOrCreate() and indexing policy with spatial index (geometry)',
      () async {
    final indexingPolicy = IndexingPolicy();
    indexingPolicy.spatialIndexes.add(
      SpatialIndexPath(
        '/location/?',
        types: [DataType.point],
        boundingBox: BoundingBox(-1, -1, 1, 1),
      ),
    );
    final collection = await database.collections.openOrCreate(collName5,
        partitionKeys: ['/id'], indexingPolicy: indexingPolicy);
    expect(collection, isNotNull);
    expect(collection.exists, isTrue);
  });

  test(
      'Create collection with openOrCreate() and indexing policy with spatial index (geography)',
      () async {
    final indexingPolicy = IndexingPolicy();
    indexingPolicy.spatialIndexes.add(
      SpatialIndexPath(
        '/location/?',
        types: [DataType.point],
      ),
    );
    final collection = await database.collections.openOrCreate(collName6,
        partitionKeys: ['/id'], indexingPolicy: indexingPolicy);
    expect(collection, isNotNull);
    expect(collection.exists, isTrue);
  });

  test('Create collection with openOrCreate(), then update indexing policy',
      () async {
    final collection = await database.collections
        .openOrCreate(collName7, partitionKeys: ['/id']);

    expect(collection, isNotNull);
    expect(collection.exists, isTrue);

    final indexingPolicy = IndexingPolicy();
    indexingPolicy.excludedPaths.add(IndexPath('/*'));
    indexingPolicy.includedPaths.add(IndexPath('/gid/?'));
    await collection.setIndexingPolicy(indexingPolicy);
  });

  test('Open collection with openOrCreate()', () async {
    final collection = await database.collections.openOrCreate(collName1);
    expect(collection, isNotNull);
    expect(collection.exists, isTrue);
  });

  test('Create collection with create() fails', () async {
    await expectLater(
      database.collections.create(collName1, partitionKeys: ['/id']),
      throwsA(isA<ConflictException>()),
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
