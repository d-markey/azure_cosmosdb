import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';
import 'package:test/test.dart';

import '../classes/test_document.dart';
import '../classes/test_document_typed.dart';
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
  late final CosmosDbCollection typedCollection;

  setUpAll(() async {
    database = await cosmosDB.databases.create(getTempName());
    collection = await database.collections.create(
      'items',
      partitionKey: PartitionKeySpec.id,
    );
    collection.registerBuilder<TestDocument>(TestDocument.fromJson);
    typedCollection = await database.collections.create(
      'items_by_type',
      partitionKey: PartitionKeySpec('/t'),
    );
    typedCollection
        .registerBuilder<TestTypedDocument>(TestTypedDocument.fromJson);
  });

  tearDownAll(() async {
    await cosmosDB.databases.delete(database);
  });

  test('Add batch of documents', () async {
    cosmosDB.enableLog(withBody: true, withHeader: true);
    try {
      final pk = await typedCollection.getPkRanges();
      print(pk);

      final doc1 = TestTypedDocument('1', 'info', 'TEST #1', [1, 2, 3]);
      final doc2 = TestTypedDocument('2', 'info', 'TEST #2', [2, 3, 5]);

      final doc1pk = typedCollection.partitionKeySpec.from(doc1)!;

      final batch = TransactionalBatch(isAtomic: true);
      batch.create(doc1, pk: typedCollection.partitionKeySpec);
      batch.upsert(doc2, pk: typedCollection.partitionKeySpec);
      batch.read('1', partitionKey: doc1pk);

      final res = await typedCollection.execute(batch);
      print(res);

      final doc = await typedCollection.find<TestTypedDocument>(doc1.id,
          partitionKey: doc1pk);
      expect(doc, isNotNull);
      expect(doc!.id, equals(doc1.id));
    } finally {
      cosmosDB.disableLog();
    }
  });
}
