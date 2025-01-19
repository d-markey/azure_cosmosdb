import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';
import 'package:azure_cosmosdb/src/_internal/_extensions.dart';
import 'package:test/test.dart';

import '../classes/test_helpers.dart';

void main() async {
  final cosmosDB = await getTestInstance(preview: true);
  if (cosmosDB != null) {
    run(cosmosDB);
  }
}

void run(CosmosDbServer cosmosDB) {
  final unexistingContainer = 'not_found';
  final newContainer = getTempName('test');

  late CosmosDbDatabase database;
  late CosmosDbDatabase database_20000RU;

  setUpAll(() async {
    database = await cosmosDB.databases.create(getTempName('small'));
    database_20000RU = await cosmosDB.databases
        .create(getTempName('large'), throughput: CosmosDbThroughput(20000));
  });

  tearDownAll(() async {
    await cosmosDB.databases.delete(database);
    await cosmosDB.databases.delete(database_20000RU);
  });

  test('List containers before creation', () async {
    final list = await database.containers.list();
    expect(list.where((c) => c.id == unexistingContainer), isEmpty);
  });

  test('Open a non-existing containers fails', () async {
    await expectLater(
      database.containers.open(getTempName()),
      throwsA(isA<NotFoundException>()),
    );
    await expectLater(
      database.containers.open(unexistingContainer),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('Delete a non-existing container fails when throwOnNotFound is true',
      () async {
    final container = CosmosDbContainer(database, getTempName());
    expect(container.exists, isNull);
    await expectLater(
      database.containers.delete(container, throwOnNotFound: true),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('Delete a non-existing container succeeds when throwOnNotFound is false',
      () async {
    final container = CosmosDbContainer(database, getTempName());
    expect(container.exists, isNull);
    await database.containers.delete(container);
    expect(container.exists, isFalse);
  });

  test('Create container with openOrCreate()', () async {
    final container = await database.containers
        .openOrCreate(getTempName(), partitionKey: PartitionKeySpec.id);
    expect(container, isNotNull);
    expect(container.exists, isTrue);
    await database.containers.delete(container);
  });

  test('Create container with openOrCreate() - no provisioned throughput',
      () async {
    final container = await database.containers.openOrCreate(getTempName(),
        partitionKey: PartitionKeySpec.id,
        throughput: CosmosDbThroughput.none());
    expect(container, isNotNull);
    expect(container.exists, isTrue);
    await database.containers.delete(container);
  });

  test('Create container with openOrCreate() - multi-hash partition key',
      () async {
    final container = await database.containers.openOrCreate(getTempName(),
        partitionKey: PartitionKeySpec.hierarchical(['/id', '/type']));
    expect(container, isNotNull);
    expect(container.exists, isTrue);
    await database.containers.delete(container);
  }, skip: !cosmosDB.features.hierarchicalPartitioning);

  test('Create container with openOrCreate() - fixed throughput', () async {
    final container = await database_20000RU.containers.openOrCreate(
        getTempName(),
        partitionKey: PartitionKeySpec.id,
        throughput: CosmosDbThroughput.minimum);
    expect(container, isNotNull);
    expect(container.exists, isTrue);
    await database_20000RU.containers.delete(container);
  });

  test('Create container with openOrCreate() - auto-scale', () async {
    final container = await database_20000RU.containers.openOrCreate(
        getTempName(),
        partitionKey: PartitionKeySpec.id,
        throughput: CosmosDbThroughput.autoScale(2000));
    expect(container, isNotNull);
    expect(container.exists, isTrue);
    await database_20000RU.containers.delete(container);
  });

  test('Create container with openOrCreate() and simple indexing policy',
      () async {
    final indexingPolicy = IndexingPolicy();
    indexingPolicy.excludedPaths.add(IndexPath('/*'));
    indexingPolicy.includedPaths.add(IndexPath('/gid/?'));
    final container = await database.containers.openOrCreate(getTempName(),
        partitionKey: PartitionKeySpec('/gid'), indexingPolicy: indexingPolicy);
    expect(container, isNotNull);
    expect(container.exists, isTrue);
    await database.containers.delete(container);
  });

  test(
      'Create container with openOrCreate() and indexing policy with composite index',
      () async {
    final indexingPolicy = IndexingPolicy();
    indexingPolicy.excludedPaths.add(IndexPath('/*'));
    indexingPolicy.includedPaths.add(IndexPath('/gid/?'));
    indexingPolicy.compositeIndexes.add([
      IndexPath('/label', order: IndexOrder.ascending),
      IndexPath('/"due-date"', order: IndexOrder.descending),
    ]);
    final container = await database.containers.openOrCreate(getTempName(),
        partitionKey: PartitionKeySpec('/gid'), indexingPolicy: indexingPolicy);
    expect(container, isNotNull);
    expect(container.exists, isTrue);
    await database.containers.delete(container);
  });

  test('Open container and check partition key spec', () async {
    final container = await database.containers
        .openOrCreate(getTempName(), partitionKey: PartitionKeySpec('/gid'));
    expect(container, isNotNull);
    expect(container.exists, isTrue);
    expect(container.partitionKeySpec, equals(PartitionKeySpec('/gid')));
    await database.containers.delete(container);
  });

  test(
      'Create container with openOrCreate() and indexing policy with spatial index (geometry)',
      () async {
    final indexingPolicy = IndexingPolicy();
    indexingPolicy.spatialIndexes.add(
      SpatialIndexPath(
        '/location/?',
        types: [DataType.point],
        boundingBox: BoundingBox(-1, -1, 1, 1),
      ),
    );
    final container = await database.containers.openOrCreate(getTempName(),
        partitionKey: PartitionKeySpec.id, indexingPolicy: indexingPolicy);
    expect(container, isNotNull);
    expect(container.exists, isTrue);
    await database.containers.delete(container);
  });

  test(
      'Create container with openOrCreate() and indexing policy with spatial index (geography)',
      () async {
    final indexingPolicy = IndexingPolicy();
    indexingPolicy.spatialIndexes.add(
      SpatialIndexPath(
        '/location/?',
        types: [DataType.point],
      ),
    );
    final container = await database.containers.openOrCreate(getTempName(),
        partitionKey: PartitionKeySpec.id, indexingPolicy: indexingPolicy);
    expect(container, isNotNull);
    expect(container.exists, isTrue);
    await database.containers.delete(container);
  });

  test('Create container with openOrCreate(), then update indexing policy',
      () async {
    final container = await database.containers
        .openOrCreate(getTempName(), partitionKey: PartitionKeySpec.id);

    expect(container, isNotNull);
    expect(container.exists, isTrue);

    final indexingPolicy = IndexingPolicy();
    indexingPolicy.excludedPaths.add(IndexPath('/*'));
    indexingPolicy.includedPaths.add(IndexPath('/gid/?'));
    await container.setIndexingPolicy(indexingPolicy);
    await database.containers.delete(container);
  });

  test('Open container with openOrCreate()', () async {
    final container = await database.containers
        .openOrCreate(newContainer, partitionKey: PartitionKeySpec.id);
    expect(container, isNotNull);
    expect(container.exists, isTrue);
    expect(container.partitionKeySpec, equals(PartitionKeySpec.id));
  });

  test('Create existing container with create() fails', () async {
    await expectLater(
      database.containers
          .create(newContainer, partitionKey: PartitionKeySpec.id),
      throwsA(isA<ConflictException>()),
    );
  });

  test('List containers after creation', () async {
    final list = await database.containers.list();
    final container = list.singleOrDefault((coll) => coll.id == newContainer);
    expect(container, isNotNull);
    expect(container?.exists, isTrue);
    expect(container?.partitionKeySpec, equals(PartitionKeySpec.id));
  });

  test('Get containers partition key ranges', () async {
    final coll = await database.containers.openOrCreate(newContainer);
    final pkranges = await coll.getPkRanges();
    expect(pkranges, isNotEmpty);
  });

  test('Delete container', () async {
    final container = await database.containers.openOrCreate(newContainer);
    expect(container.exists, isTrue);
    await database.containers.delete(container);
    expect(container.exists, isFalse);
  });

  test('List containers after deletion', () async {
    final list = await database.containers.list();
    final container = list.singleOrDefault((coll) => coll.id == newContainer);
    expect(container, isNull);
  });

  test('Get containers partition key ranges - large database', () async {
    final container = await database_20000RU.containers.create(getTempName(),
        partitionKey: PartitionKeySpec.id,
        throughput: CosmosDbThroughput(15000));
    final pkranges = await container.getPkRanges();
    expect(pkranges, isNotEmpty);
    expect(pkranges.length, greaterThanOrEqualTo(2));
    await database_20000RU.containers.delete(container);
  });
}
