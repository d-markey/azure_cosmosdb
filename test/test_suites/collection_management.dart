import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';
import 'package:azure_cosmosdb/src/_internal/_linq_extensions.dart';
import 'package:test/test.dart';

import '../classes/test_helpers.dart';

void main() async {
  final cosmosDB = await getTestInstance();
  if (cosmosDB != null) {
    run(cosmosDB);
  }
}

void run(CosmosDbServer cosmosDB) {
  final collTest1 = 'test_1';
  final collTest2 = 'test_2';
  final collNotFoundTest = 'not_found';
  final collIndexTest1 = 'idx_test_1';
  final collIndexTest2 = 'idx_test_2';
  final collGeometryTest = 'geom_test';
  final collGeography = 'geos_test';
  final collMultiTest = 'multi_test';

  final collNames = {
    collTest1,
    collTest2,
    collNotFoundTest,
    collIndexTest1,
    collIndexTest2,
    collGeometryTest,
    collGeography,
    collMultiTest,
  };

  late CosmosDbDatabase database;
  late CosmosDbDatabase database_4000RU;

  setUpAll(() async {
    database = await cosmosDB.databases.create(getTempName('test'));
    database_4000RU = await cosmosDB.databases.create(
        getTempName('test_manual'),
        throughput: CosmosDbThroughput(4000));
  });

  tearDownAll(() async {
    await cosmosDB.databases.delete(database);
    await cosmosDB.databases.delete(database_4000RU);
  });

  test('List collections before creation', () async {
    final list = await database.collections.list();
    expect(list.where((c) => collNames.contains(c.id)), isEmpty);
  });

  test('Open a non-existing collection fails', () async {
    await expectLater(
      database.collections.open(collTest1),
      throwsA(isA<NotFoundException>()),
    );
    await expectLater(
      database.collections.open(collNotFoundTest),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('Delete a non-existing collection fails when throwOnNotFound is true',
      () async {
    final collection = CosmosDbCollection(database, collTest1);
    expect(collection.exists, isNull);
    await expectLater(
      database.collections.delete(collection, throwOnNotFound: true),
      throwsA(isA<NotFoundException>()),
    );
  });

  test(
      'Delete a non-existing collection succeeds when throwOnNotFound is false',
      () async {
    final collection = CosmosDbCollection(database, collTest1);
    expect(collection.exists, isNull);
    await database.collections.delete(collection, throwOnNotFound: false);
    expect(collection.exists, isFalse);
  });

  test('Create collection with openOrCreate()', () async {
    final collection = await database.collections
        .openOrCreate(collTest1, partitionKey: PartitionKeySpec.id);
    expect(collection, isNotNull);
    expect(collection.exists, isTrue);
  });

  test('Create collection with openOrCreate() - multi-hash partition key',
      () async {
    final collection = await database.collections.openOrCreate(collMultiTest,
        partitionKey: PartitionKeySpec.multi(['/id', '/type']));
    expect(collection, isNotNull);
    expect(collection.exists, isTrue);
  }, skip: true);

  test('Create collection with openOrCreate() - fixed throughput', () async {
    final collection = await database_4000RU.collections.openOrCreate(
        getTempName('coll'),
        partitionKey: PartitionKeySpec.id,
        throughput: CosmosDbThroughput.minimum);
    expect(collection, isNotNull);
    expect(collection.exists, isTrue);
    await database.collections.delete(collection);
  });

  test('Create collection with openOrCreate() - auto-scale', () async {
    final collection = await database_4000RU.collections.openOrCreate(
        getTempName('coll3'),
        partitionKey: PartitionKeySpec.id,
        throughput: CosmosDbThroughput.autoScale(2000));
    expect(collection, isNotNull);
    expect(collection.exists, isTrue);
    await database.collections.delete(collection);
  });

  test('Create collection with openOrCreate() and simple indexing policy',
      () async {
    final indexingPolicy = IndexingPolicy();
    indexingPolicy.excludedPaths.add(IndexPath('/*'));
    indexingPolicy.includedPaths.add(IndexPath('/gid/?'));
    final collection = await database.collections.openOrCreate(collIndexTest1,
        partitionKey: PartitionKeySpec('/gid'), indexingPolicy: indexingPolicy);
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
    final collection = await database.collections.openOrCreate(collIndexTest2,
        partitionKey: PartitionKeySpec('/gid'), indexingPolicy: indexingPolicy);
    expect(collection, isNotNull);
    expect(collection.exists, isTrue);
  });

  test('Open collection and check partition key spec', () async {
    final collection = await database.collections.openOrCreate(collIndexTest2);
    expect(collection, isNotNull);
    expect(collection.exists, isTrue);
    expect(collection.partitionKeySpec, equals(PartitionKeySpec('/gid')));
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
    final collection = await database.collections.openOrCreate(collGeometryTest,
        partitionKey: PartitionKeySpec.id, indexingPolicy: indexingPolicy);
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
    final collection = await database.collections.openOrCreate(collGeography,
        partitionKey: PartitionKeySpec.id, indexingPolicy: indexingPolicy);
    expect(collection, isNotNull);
    expect(collection.exists, isTrue);
  });

  test('Create collection with openOrCreate(), then update indexing policy',
      () async {
    final collection = await database.collections
        .openOrCreate(collTest2, partitionKey: PartitionKeySpec.id);

    expect(collection, isNotNull);
    expect(collection.exists, isTrue);

    final indexingPolicy = IndexingPolicy();
    indexingPolicy.excludedPaths.add(IndexPath('/*'));
    indexingPolicy.includedPaths.add(IndexPath('/gid/?'));
    await collection.setIndexingPolicy(indexingPolicy);
  });

  test('Open collection with openOrCreate()', () async {
    final collection = await database.collections.openOrCreate(collTest1);
    expect(collection, isNotNull);
    expect(collection.exists, isTrue);
    expect(collection.partitionKeySpec, equals(PartitionKeySpec.id));
  });

  test('Create existing collection with create() fails', () async {
    await expectLater(
      database.collections.create(collTest1, partitionKey: PartitionKeySpec.id),
      throwsA(isA<ConflictException>()),
    );
  });

  test('List collections after creation', () async {
    final list = await database.collections.list();
    final collection = list.singleOrDefault((coll) => coll.id == collTest1);
    expect(collection, isNotNull);
    expect(collection?.exists, isTrue);
    expect(collection?.partitionKeySpec, equals(PartitionKeySpec.id));
  });

  test('Get collections partition key ranges', () async {
    final coll = await database.collections.openOrCreate(collTest1);
    final pkranges = await coll.getPkRanges();
    expect(pkranges, isNotEmpty);
  });

  test('Delete collection', () async {
    final collection = await database.collections.openOrCreate(collTest1);
    expect(collection.exists, isTrue);
    await database.collections.delete(collection);
    expect(collection.exists, isFalse);
  });

  test('List collections after deletion', () async {
    final list = await database.collections.list();
    final collection = list.singleOrDefault((coll) => coll.id == collTest1);
    expect(collection, isNull);
  });
}
