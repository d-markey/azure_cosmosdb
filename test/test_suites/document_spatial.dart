import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';
import 'package:test/test.dart';

import '../classes/test_document.dart';
import '../classes/test_helpers.dart';
import '../classes/test_spatial_document.dart';

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
    final indexingPolicy = IndexingPolicy();
    indexingPolicy.spatialIndexes
        .add(SpatialIndexPath('/p/?', types: [DataType.point]));
    collection = await database.collections.create('items',
        partitionKeys: ['/id'], indexingPolicy: indexingPolicy);
    collection
        .registerBuilder<TestSpatialDocument>(TestSpatialDocument.fromJson);
  });

  tearDownAll(() async {
    await cosmosDB.databases.delete(database);
  });

  const eiffelTower = Point.geography(48.858370, 2.294481);

  test('Add a document', () async {
    cosmosDB.useLogger(print, withBody: true);
    try {
      final doc = await collection
          .add(TestSpatialDocument('1', 'Eiffel Tower', eiffelTower));
      expect(doc.label, equals('Eiffel Tower'));
    } finally {
      cosmosDB.useSilentLogger();
    }
  });
}
