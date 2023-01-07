import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';
import 'package:test/test.dart';

import '../classes/test_document.dart';
import '../classes/test_document_typed.dart';
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
  late final CosmosDbContainer typedContainer;

  setUpAll(() async {
    database = await cosmosDB.databases.create(getTempName());
    container = await database.containers.create(
      'items',
      partitionKey: PartitionKeySpec.id,
    );
    container.registerBuilder<TestDocument>(TestDocument.fromJson);
    typedContainer = await database.containers.create(
      'items_by_type',
      partitionKey: PartitionKeySpec('/t'),
    );
    typedContainer
        .registerBuilder<TestTypedDocument>(TestTypedDocument.fromJson);
  });

  tearDownAll(() async {
    await cosmosDB.databases.delete(database);
  });

  final doc1 = TestTypedDocument('1', 'info', 'Positive', [1, 2, 3, 4]);
  final doc2 = TestTypedDocument('2', 'info', 'Prime', [2, 3, 5, 7]);
  final doc3 = TestTypedDocument('3', 'info', 'Even', [2, 4, 6, 8]);
  final doc4 = TestTypedDocument('4', 'info', 'Odd', [3, 5, 7, 9]);
  final doc5 = TestTypedDocument('5', 'info', 'Zero', [0, 0, 0, 0]);
  final doc6 = TestTypedDocument('6', 'info', 'Negative', [-1, -2, -3, -4]);

  group('Atomic -', () {
    test('Create', () async {
      final pk = PartitionKey('info');

      var batch =
          typedContainer.prepareBatch<TestTypedDocument>(isAtomic: true);

      batch.create(doc1);
      batch.create(doc2);
      batch.create(doc3);
      batch.read('2', partitionKey: pk);

      final resp = await batch.execute();
      expect(resp.success, isTrue);
      expect(resp.length, equals(batch.operations.length));

      for (var res in resp.results) {
        expect(res.success, isTrue);
        expect(res.item, isA<TestTypedDocument>());
      }

      expect(resp[0]!.id, equals(doc1.id));
      expect(resp[1]!.id, equals(doc2.id));
      expect(resp[2]!.id, equals(doc3.id));
      expect(resp[3]!.id, equals(doc2.id));

      var doc = await typedContainer.find<TestTypedDocument>(doc1.id,
          partitionKey: pk);
      expect(doc, isNotNull);
      expect(doc!.id, equals(doc1.id));

      doc = await typedContainer.find<TestTypedDocument>(doc2.id,
          partitionKey: pk);
      expect(doc, isNotNull);
      expect(doc!.id, equals(doc2.id));

      doc = await typedContainer.find<TestTypedDocument>(doc3.id,
          partitionKey: pk);
      expect(doc, isNotNull);
      expect(doc!.id, equals(doc3.id));
    });

    test('Create with errors', () async {
      final pk = PartitionKey('info');

      var batch =
          typedContainer.prepareBatch<TestTypedDocument>(isAtomic: true);

      batch.create(doc4);
      batch.create(doc5);
      batch.read('2', partitionKey: pk);
      batch.create(doc2);
      batch.create(doc6);

      final resp = await batch.execute();
      expect(resp.success, isFalse);
      expect(resp.length, equals(batch.operations.length));

      for (var res in resp.results) {
        expect(res.success, isFalse);
      }

      var doc = await typedContainer.find<TestTypedDocument>(doc2.id,
          partitionKey: pk);
      expect(doc, isNotNull);

      doc = await typedContainer.find<TestTypedDocument>(doc4.id,
          partitionKey: pk);
      expect(doc, isNull);

      doc = await typedContainer.find<TestTypedDocument>(doc5.id,
          partitionKey: pk);
      expect(doc, isNull);

      doc = await typedContainer.find<TestTypedDocument>(doc6.id,
          partitionKey: pk);
      expect(doc, isNull);
    });

    test('Delete', () async {
      final pk = PartitionKey('info');

      var batch =
          typedContainer.prepareBatch<TestTypedDocument>(isAtomic: true);

      batch.delete(doc1.id, partitionKey: pk);
      batch.delete(doc2.id, partitionKey: pk);
      batch.delete(doc3.id, partitionKey: pk);

      final resp = await batch.execute();
      expect(resp.success, isTrue);
      expect(resp.length, equals(batch.operations.length));

      for (var res in resp.results) {
        expect(res.success, isTrue);
        expect(res.item, isNull);
      }

      var doc = await typedContainer.find<TestTypedDocument>(doc2.id,
          partitionKey: pk);
      expect(doc, isNull);

      doc = await typedContainer.find<TestTypedDocument>(doc6.id,
          partitionKey: pk);
      expect(doc, isNull);
    });
  });

  group('Non-Atomic - Fail on error -', () {
    test('Create', () async {
      final pk = PartitionKey('info');

      var batch = typedContainer.prepareBatch<TestTypedDocument>(
          continueOnError: false);

      batch.create(doc1);
      batch.create(doc2);
      batch.create(doc3);
      batch.read('2', partitionKey: pk);

      final resp = await batch.execute();
      expect(resp.success, isTrue);
      expect(resp.length, equals(batch.operations.length));

      for (var res in resp.results) {
        expect(res.success, isTrue);
        expect(res.item, isA<TestTypedDocument>());
      }

      expect(resp[0]!.id, equals(doc1.id));
      expect(resp[1]!.id, equals(doc2.id));
      expect(resp[2]!.id, equals(doc3.id));
      expect(resp[3]!.id, equals(doc2.id));

      var doc = await typedContainer.find<TestTypedDocument>(doc1.id,
          partitionKey: pk);
      expect(doc, isNotNull);
      expect(doc!.id, equals(doc1.id));

      doc = await typedContainer.find<TestTypedDocument>(doc2.id,
          partitionKey: pk);
      expect(doc, isNotNull);
      expect(doc!.id, equals(doc2.id));

      doc = await typedContainer.find<TestTypedDocument>(doc3.id,
          partitionKey: pk);
      expect(doc, isNotNull);
      expect(doc!.id, equals(doc3.id));
    });

    test('Create with errors', () async {
      final pk = PartitionKey('info');

      var batch = typedContainer.prepareBatch<TestTypedDocument>(
          continueOnError: false);

      batch.create(doc4);
      batch.create(doc5);
      batch.read('2', partitionKey: pk);
      batch.create(doc2);
      batch.create(doc6);

      final resp = await batch.execute();
      expect(resp.success, isFalse);
      expect(resp.length, equals(batch.operations.length));

      final results = resp.results.toList();

      expect(results[0].success, isTrue);
      expect(results[0].item, isNotNull);
      expect(results[0].item!.id, equals(doc4.id));

      expect(results[1].success, isTrue);
      expect(results[1].item, isNotNull);
      expect(results[1].item!.id, equals(doc5.id));

      expect(results[2].success, isTrue);
      expect(results[2].item, isNotNull);
      expect(results[2].item!.id, equals(doc2.id));

      expect(results[3].success, isFalse);
      expect(results[3].item, isNull);

      expect(results[4].success, isFalse);
      expect(results[4].item, isNull);

      var doc = await typedContainer.find<TestTypedDocument>(doc2.id,
          partitionKey: pk);
      expect(doc, isNotNull);

      doc = await typedContainer.find<TestTypedDocument>(doc4.id,
          partitionKey: pk);
      expect(doc, isNotNull);

      doc = await typedContainer.find<TestTypedDocument>(doc5.id,
          partitionKey: pk);
      expect(doc, isNotNull);

      doc = await typedContainer.find<TestTypedDocument>(doc6.id,
          partitionKey: pk);
      expect(doc, isNull);
    });

    test('Delete', () async {
      final pk = PartitionKey('info');

      var batch = typedContainer.prepareBatch<TestTypedDocument>(
          continueOnError: false);

      batch.delete(doc1.id, partitionKey: pk);
      batch.delete(doc2.id, partitionKey: pk);
      batch.delete(doc3.id, partitionKey: pk);
      batch.delete(doc4.id, partitionKey: pk);
      batch.delete(doc5.id, partitionKey: pk);

      final resp = await batch.execute();
      expect(resp.success, isTrue);
      expect(resp.length, equals(batch.operations.length));

      for (var res in resp.results) {
        expect(res.success, isTrue);
        expect(res.item, isNull);
      }

      var doc = await typedContainer.find<TestTypedDocument>(doc2.id,
          partitionKey: pk);
      expect(doc, isNull);

      doc = await typedContainer.find<TestTypedDocument>(doc6.id,
          partitionKey: pk);
      expect(doc, isNull);
    });
  });

  group('Non-Atomic - Continue on error -', () {
    test('Create', () async {
      final pk = PartitionKey('info');

      var batch =
          typedContainer.prepareBatch<TestTypedDocument>(continueOnError: true);

      batch.create(doc1);
      batch.create(doc2);
      batch.create(doc3);
      batch.read('2', partitionKey: pk);

      final resp = await batch.execute();
      expect(resp.success, isTrue);
      expect(resp.length, equals(batch.operations.length));

      for (var res in resp.results) {
        expect(res.success, isTrue);
        expect(res.item, isA<TestTypedDocument>());
      }

      expect(resp[0]!.id, equals(doc1.id));
      expect(resp[1]!.id, equals(doc2.id));
      expect(resp[2]!.id, equals(doc3.id));
      expect(resp[3]!.id, equals(doc2.id));

      var doc = await typedContainer.find<TestTypedDocument>(doc1.id,
          partitionKey: pk);
      expect(doc, isNotNull);
      expect(doc!.id, equals(doc1.id));

      doc = await typedContainer.find<TestTypedDocument>(doc2.id,
          partitionKey: pk);
      expect(doc, isNotNull);
      expect(doc!.id, equals(doc2.id));

      doc = await typedContainer.find<TestTypedDocument>(doc3.id,
          partitionKey: pk);
      expect(doc, isNotNull);
      expect(doc!.id, equals(doc3.id));
    });

    test('Create with errors', () async {
      final pk = PartitionKey('info');

      var batch =
          typedContainer.prepareBatch<TestTypedDocument>(continueOnError: true);

      batch.create(doc4);
      batch.create(doc5);
      batch.read('2', partitionKey: pk);
      batch.create(doc2);
      batch.create(doc6);

      final resp = await batch.execute();
      expect(resp.success, isFalse);
      expect(resp.length, equals(batch.operations.length));

      final results = resp.results.toList();

      expect(results[0].success, isTrue);
      expect(results[0].item, isNotNull);
      expect(results[0].item!.id, equals(doc4.id));

      expect(results[1].success, isTrue);
      expect(results[1].item, isNotNull);
      expect(results[1].item!.id, equals(doc5.id));

      expect(results[2].success, isTrue);
      expect(results[2].item, isNotNull);
      expect(results[2].item!.id, equals(doc2.id));

      expect(results[3].success, isFalse);
      expect(results[3].item, isNull);

      expect(results[4].success, isTrue);
      expect(results[4].item, isNotNull);
      expect(results[4].item!.id, equals(doc6.id));

      var doc = await typedContainer.find<TestTypedDocument>(doc2.id,
          partitionKey: pk);
      expect(doc, isNotNull);

      doc = await typedContainer.find<TestTypedDocument>(doc4.id,
          partitionKey: pk);
      expect(doc, isNotNull);

      doc = await typedContainer.find<TestTypedDocument>(doc5.id,
          partitionKey: pk);
      expect(doc, isNotNull);

      doc = await typedContainer.find<TestTypedDocument>(doc6.id,
          partitionKey: pk);
      expect(doc, isNotNull);
    });

    test('Delete', () async {
      final pk = PartitionKey('info');

      var batch =
          typedContainer.prepareBatch<TestTypedDocument>(continueOnError: true);

      batch.delete(doc1.id, partitionKey: pk);
      batch.delete(doc2.id, partitionKey: pk);
      batch.delete(doc3.id, partitionKey: pk);
      batch.delete(doc4.id, partitionKey: pk);
      batch.delete(doc5.id, partitionKey: pk);
      batch.delete(doc6.id, partitionKey: pk);

      final resp = await batch.execute();
      expect(resp.success, isTrue);
      expect(resp.length, equals(batch.operations.length));

      for (var res in resp.results) {
        expect(res.success, isTrue);
        expect(res.item, isNull);
      }

      var doc = await typedContainer.find<TestTypedDocument>(doc2.id,
          partitionKey: pk);
      expect(doc, isNull);

      doc = await typedContainer.find<TestTypedDocument>(doc6.id,
          partitionKey: pk);
      expect(doc, isNull);
    });
  });
}
