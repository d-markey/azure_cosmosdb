import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';
import 'package:azure_cosmosdb/src/partition/_partition_key_hash_v2.dart';
import 'package:test/test.dart';

import '../classes/test_document_typed.dart';
import '../classes/test_helpers.dart';

void main() async {
  final cosmosDB = await getTestInstance(preview: true);
  if (cosmosDB != null) {
    run(cosmosDB);
  }
}

class PKInfo {
  PKInfo(this.value)
      : pk = PartitionKey(value),
        hash = PartitionKeyHashV2.string(value);

  final String value;
  final PartitionKey pk;
  final PartitionKeyHashV2 hash;
}

void run(CosmosDbServer cosmosDB) {
  late final CosmosDbDatabase database;
  late final CosmosDbContainer typedContainer;

  PKInfo pk1 = PKInfo('1');
  PKInfo pk2 = PKInfo('2');
  PKInfo pk3 = PKInfo('3');

  final doc1_1 = TestTypedDocument('1', pk1.value, 'Positive', [1, 2, 3, 4]);
  final doc1_2 = TestTypedDocument('2', pk1.value, 'Prime', [2, 3, 5, 7]);
  final doc1_3 = TestTypedDocument('3', pk1.value, 'Even', [2, 4, 6, 8]);
  final doc1_4 = TestTypedDocument('4', pk1.value, 'Odd', [3, 5, 7, 9]);
  final doc1_5 = TestTypedDocument('5', pk1.value, 'Zero', [0, 0, 0, 0]);
  final doc1_6 =
      TestTypedDocument('6', pk1.value, 'Negative', [-1, -2, -3, -4]);

  // ignore: unused_local_variable
  final doc2_1 = TestTypedDocument('1', pk2.value, 'Positive', [1, 2, 3, 4]);
  final doc2_2 = TestTypedDocument('2', pk2.value, 'Prime', [2, 3, 5, 7]);
  // ignore: unused_local_variable
  final doc2_3 = TestTypedDocument('3', pk2.value, 'Even', [2, 4, 6, 8]);
  // ignore: unused_local_variable
  final doc2_4 = TestTypedDocument('4', pk2.value, 'Odd', [3, 5, 7, 9]);
  // ignore: unused_local_variable
  final doc2_5 = TestTypedDocument('5', pk2.value, 'Zero', [0, 0, 0, 0]);
  // ignore: unused_local_variable
  final doc2_6 =
      TestTypedDocument('6', pk2.value, 'Negative', [-1, -2, -3, -4]);

  // ignore: unused_local_variable
  final doc3_1 = TestTypedDocument('1', pk3.value, 'Positive', [1, 2, 3, 4]);
  final doc3_2 = TestTypedDocument('2', pk3.value, 'Prime', [2, 3, 5, 7]);
  // ignore: unused_local_variable
  final doc3_3 = TestTypedDocument('3', pk3.value, 'Even', [2, 4, 6, 8]);
  // ignore: unused_local_variable
  final doc3_4 = TestTypedDocument('4', pk3.value, 'Odd', [3, 5, 7, 9]);
  // ignore: unused_local_variable
  final doc3_5 = TestTypedDocument('5', pk3.value, 'Zero', [0, 0, 0, 0]);
  // ignore: unused_local_variable
  final doc3_6 =
      TestTypedDocument('6', pk3.value, 'Negative', [-1, -2, -3, -4]);

  setUpAll(() async {
    database = await cosmosDB.databases.create(getTempName());
    typedContainer = await database.containers.create(
      getTempName('typed'),
      partitionKey: PartitionKeySpec('/t'),
      throughput: CosmosDbThroughput(10000),
    );
    typedContainer
        .registerBuilder<TestTypedDocument>(TestTypedDocument.fromJson);

    final pkRanges = await typedContainer.getPkRanges();
    // print(pkRanges);
    expect(pkRanges, hasLength(greaterThan(1)));

    final pkr1 = pkRanges.findFor(pk1.pk);
    final pkr2 = pkRanges.findFor(pk2.pk);
    final pkr3 = pkRanges.findFor(pk3.pk);
    // print('${pk1.value} -> ${pk1.hash.hex} -> $pkr1');
    // print('${pk2.value} -> ${pk2.hash.hex} -> $pkr2');
    // print('${pk3.value} -> ${pk3.hash.hex} -> $pkr3');
    expect(pkr1, isNot(equals(pkr2)));
    expect(pkr3, equals(pkr1));
  });

  tearDownAll(() async {
    await cosmosDB.databases.delete(database);
  });

  group('Atomic -', () {
    test('Create', () async {
      var batch =
          typedContainer.prepareBatch<TestTypedDocument>(isAtomic: true);

      batch.create(doc1_1);
      batch.upsert(doc1_2);
      batch.create(doc1_3);
      batch.read('2', partitionKey: pk1.pk);

      final resp = await batch.execute();
      expect(resp.success, isTrue);
      expect(resp.length, equals(batch.operations.length));

      for (var res in resp.results) {
        expect(res.success, isTrue);
        expect(res.item, isA<TestTypedDocument>());
      }

      expect(resp[0]!.id, equals(doc1_1.id));
      expect(resp[1]!.id, equals(doc1_2.id));
      expect(resp[2]!.id, equals(doc1_3.id));
      expect(resp[3]!.id, equals(doc1_2.id));

      var doc = await typedContainer.find<TestTypedDocument>(doc1_1.id,
          partitionKey: pk1.pk);
      expect(doc, isNotNull);
      expect(doc!.id, equals(doc1_1.id));

      doc = await typedContainer.find<TestTypedDocument>(doc1_2.id,
          partitionKey: pk1.pk);
      expect(doc, isNotNull);
      expect(doc!.id, equals(doc1_2.id));

      doc = await typedContainer.find<TestTypedDocument>(doc1_3.id,
          partitionKey: pk1.pk);
      expect(doc, isNotNull);
      expect(doc!.id, equals(doc1_3.id));
    });

    test('Create with errors', () async {
      var batch =
          typedContainer.prepareBatch<TestTypedDocument>(isAtomic: true);

      batch.create(doc1_4);
      batch.create(doc1_5);
      batch.read('2', partitionKey: pk1.pk);
      batch.create(doc1_2);
      batch.create(doc1_6);

      final resp = await batch.execute();
      expect(resp.success, isFalse);
      expect(resp.length, equals(batch.operations.length));

      for (var res in resp.results) {
        expect(res.success, isFalse);
      }

      var doc = await typedContainer.find<TestTypedDocument>(doc1_2.id,
          partitionKey: pk1.pk);
      expect(doc, isNotNull);

      doc = await typedContainer.find<TestTypedDocument>(doc1_4.id,
          partitionKey: pk1.pk);
      expect(doc, isNull);

      doc = await typedContainer.find<TestTypedDocument>(doc1_5.id,
          partitionKey: pk1.pk);
      expect(doc, isNull);

      doc = await typedContainer.find<TestTypedDocument>(doc1_6.id,
          partitionKey: pk1.pk);
      expect(doc, isNull);
    });

    test('Delete', () async {
      var batch =
          typedContainer.prepareBatch<TestTypedDocument>(isAtomic: true);

      batch.delete(doc1_1.id, partitionKey: pk1.pk);
      batch.delete(doc1_2.id, partitionKey: pk1.pk);
      batch.delete(doc1_3.id, partitionKey: pk1.pk);

      final resp = await batch.execute();
      expect(resp.success, isTrue);
      expect(resp.length, equals(batch.operations.length));

      for (var res in resp.results) {
        expect(res.success, isTrue);
        expect(res.item, isNull);
      }

      var doc = await typedContainer.find<TestTypedDocument>(doc1_2.id,
          partitionKey: pk1.pk);
      expect(doc, isNull);

      doc = await typedContainer.find<TestTypedDocument>(doc1_6.id,
          partitionKey: pk1.pk);
      expect(doc, isNull);
    });

    test('Create - in different partition key ranges', () async {
      var batch =
          typedContainer.prepareBatch<TestTypedDocument>(isAtomic: true);

      batch.create(doc1_1);
      batch.create(doc1_2);
      batch.create(doc2_2);
      batch.read('2', partitionKey: pk1.pk);
      batch.read('2', partitionKey: pk2.pk);

      try {
        await batch.execute();
        throw Exception('The request did not fail');
      } on PartitionKeyException catch (ex) {
        expect(ex.toString().toLowerCase(), contains('several partition key'));
      }

      var doc = await typedContainer.find<TestTypedDocument>(doc1_1.id,
          partitionKey: pk1.pk);
      expect(doc, isNull);

      doc = await typedContainer.find<TestTypedDocument>(doc1_2.id,
          partitionKey: pk1.pk);
      expect(doc, isNull);

      doc = await typedContainer.find<TestTypedDocument>(doc2_2.id,
          partitionKey: pk2.pk);
      expect(doc, isNull);
    });

    test('Create - in same partition key range with different partition key',
        () async {
      var batch =
          typedContainer.prepareBatch<TestTypedDocument>(isAtomic: true);

      batch.create(doc1_1);
      batch.create(doc1_2);
      batch.create(doc3_2);
      batch.read('2', partitionKey: pk1.pk);
      batch.read('2', partitionKey: pk3.pk);

      try {
        await batch.execute();
        throw Exception('The request did not fail');
      } on BadRequestException catch (ex) {
        expect(ex.toString().toLowerCase(),
            contains('different partition key values'));
      }

      var doc = await typedContainer.find<TestTypedDocument>(doc1_1.id,
          partitionKey: pk1.pk);
      expect(doc, isNull);

      doc = await typedContainer.find<TestTypedDocument>(doc1_2.id,
          partitionKey: pk1.pk);
      expect(doc, isNull);

      doc = await typedContainer.find<TestTypedDocument>(doc2_2.id,
          partitionKey: pk2.pk);
      expect(doc, isNull);
    });
  });

  group('Non-Atomic - Fail on error -', () {
    test('Create', () async {
      var batch = typedContainer.prepareBatch<TestTypedDocument>(
          continueOnError: false);

      batch.create(doc1_1);
      batch.upsert(doc1_2);
      batch.create(doc1_3);
      batch.read('2', partitionKey: pk1.pk);

      final resp = await batch.execute();
      expect(resp.success, isTrue);
      expect(resp.length, equals(batch.operations.length));

      for (var res in resp.results) {
        expect(res.success, isTrue);
        expect(res.item, isA<TestTypedDocument>());
      }

      expect(resp[0]!.id, equals(doc1_1.id));
      expect(resp[1]!.id, equals(doc1_2.id));
      expect(resp[2]!.id, equals(doc1_3.id));
      expect(resp[3]!.id, equals(doc1_2.id));

      var doc = await typedContainer.find<TestTypedDocument>(doc1_1.id,
          partitionKey: pk1.pk);
      expect(doc, isNotNull);
      expect(doc!.id, equals(doc1_1.id));

      doc = await typedContainer.find<TestTypedDocument>(doc1_2.id,
          partitionKey: pk1.pk);
      expect(doc, isNotNull);
      expect(doc!.id, equals(doc1_2.id));

      doc = await typedContainer.find<TestTypedDocument>(doc1_3.id,
          partitionKey: pk1.pk);
      expect(doc, isNotNull);
      expect(doc!.id, equals(doc1_3.id));
    });

    test('Create with errors', () async {
      var batch = typedContainer.prepareBatch<TestTypedDocument>(
          continueOnError: false);

      batch.create(doc1_4);
      batch.create(doc1_5);
      batch.read('2', partitionKey: pk1.pk);
      batch.create(doc1_2);
      batch.create(doc1_6);

      final resp = await batch.execute();
      expect(resp.success, isFalse);
      expect(resp.length, equals(batch.operations.length));

      final results = resp.results.toList();

      expect(results[0].success, isTrue);
      expect(results[0].item, isNotNull);
      expect(results[0].item!.id, equals(doc1_4.id));

      expect(results[1].success, isTrue);
      expect(results[1].item, isNotNull);
      expect(results[1].item!.id, equals(doc1_5.id));

      expect(results[2].success, isTrue);
      expect(results[2].item, isNotNull);
      expect(results[2].item!.id, equals(doc1_2.id));

      expect(results[3].success, isFalse);
      expect(results[3].item, isNull);

      expect(results[4].success, isFalse);
      expect(results[4].item, isNull);

      var doc = await typedContainer.find<TestTypedDocument>(doc1_2.id,
          partitionKey: pk1.pk);
      expect(doc, isNotNull);

      doc = await typedContainer.find<TestTypedDocument>(doc1_4.id,
          partitionKey: pk1.pk);
      expect(doc, isNotNull);

      doc = await typedContainer.find<TestTypedDocument>(doc1_5.id,
          partitionKey: pk1.pk);
      expect(doc, isNotNull);

      doc = await typedContainer.find<TestTypedDocument>(doc1_6.id,
          partitionKey: pk1.pk);
      expect(doc, isNull);
    });

    test('Delete', () async {
      var batch = typedContainer.prepareBatch<TestTypedDocument>(
          continueOnError: false);

      batch.delete(doc1_1.id, partitionKey: pk1.pk);
      batch.delete(doc1_2.id, partitionKey: pk1.pk);
      batch.delete(doc1_3.id, partitionKey: pk1.pk);
      batch.delete(doc1_4.id, partitionKey: pk1.pk);
      batch.delete(doc1_5.id, partitionKey: pk1.pk);

      final resp = await batch.execute();
      expect(resp.success, isTrue);
      expect(resp.length, equals(batch.operations.length));

      for (var res in resp.results) {
        expect(res.success, isTrue);
        expect(res.item, isNull);
      }

      var doc = await typedContainer.find<TestTypedDocument>(doc1_2.id,
          partitionKey: pk1.pk);
      expect(doc, isNull);

      doc = await typedContainer.find<TestTypedDocument>(doc1_6.id,
          partitionKey: pk1.pk);
      expect(doc, isNull);
    });

    test('Create - in different partition key ranges', () async {
      var batch =
          typedContainer.prepareBatch<TestTypedDocument>(isAtomic: true);

      batch.create(doc1_1);
      batch.create(doc1_2);
      batch.create(doc2_2);
      batch.read('2', partitionKey: pk1.pk);
      batch.read('2', partitionKey: pk2.pk);

      try {
        await batch.execute();
        throw Exception('The request did not fail');
      } on PartitionKeyException catch (ex) {
        expect(ex.toString().toLowerCase(), contains('several partition key'));
      }

      var doc = await typedContainer.find<TestTypedDocument>(doc1_1.id,
          partitionKey: pk1.pk);
      expect(doc, isNull);

      doc = await typedContainer.find<TestTypedDocument>(doc1_2.id,
          partitionKey: pk1.pk);
      expect(doc, isNull);

      doc = await typedContainer.find<TestTypedDocument>(doc2_2.id,
          partitionKey: pk2.pk);
      expect(doc, isNull);
    });

    test('Create - in same partition key range with different partition key',
        () async {
      var batch =
          typedContainer.prepareBatch<TestTypedDocument>(isAtomic: true);

      batch.create(doc1_1);
      batch.create(doc1_2);
      batch.create(doc3_2);
      batch.read('2', partitionKey: pk1.pk);
      batch.read('2', partitionKey: pk3.pk);

      try {
        await batch.execute();
        throw Exception('The request did not fail');
      } on BadRequestException catch (ex) {
        expect(ex.toString().toLowerCase(),
            contains('different partition key values'));
      }

      var doc = await typedContainer.find<TestTypedDocument>(doc1_1.id,
          partitionKey: pk1.pk);
      expect(doc, isNull);

      doc = await typedContainer.find<TestTypedDocument>(doc1_2.id,
          partitionKey: pk1.pk);
      expect(doc, isNull);

      doc = await typedContainer.find<TestTypedDocument>(doc2_2.id,
          partitionKey: pk2.pk);
      expect(doc, isNull);
    });
  });

  group('Non-Atomic - Continue on error -', () {
    test('Create', () async {
      var batch =
          typedContainer.prepareBatch<TestTypedDocument>(continueOnError: true);

      batch.create(doc1_1);
      batch.upsert(doc1_2);
      batch.create(doc1_3);
      batch.read('2', partitionKey: pk1.pk);

      final resp = await batch.execute();
      expect(resp.success, isTrue);
      expect(resp.length, equals(batch.operations.length));

      for (var res in resp.results) {
        expect(res.success, isTrue);
        expect(res.item, isA<TestTypedDocument>());
      }

      expect(resp[0]!.id, equals(doc1_1.id));
      expect(resp[1]!.id, equals(doc1_2.id));
      expect(resp[2]!.id, equals(doc1_3.id));
      expect(resp[3]!.id, equals(doc1_2.id));

      var doc = await typedContainer.find<TestTypedDocument>(doc1_1.id,
          partitionKey: pk1.pk);
      expect(doc, isNotNull);
      expect(doc!.id, equals(doc1_1.id));

      doc = await typedContainer.find<TestTypedDocument>(doc1_2.id,
          partitionKey: pk1.pk);
      expect(doc, isNotNull);
      expect(doc!.id, equals(doc1_2.id));

      doc = await typedContainer.find<TestTypedDocument>(doc1_3.id,
          partitionKey: pk1.pk);
      expect(doc, isNotNull);
      expect(doc!.id, equals(doc1_3.id));
    });

    test('Create with errors', () async {
      var batch =
          typedContainer.prepareBatch<TestTypedDocument>(continueOnError: true);

      batch.create(doc1_4);
      batch.create(doc1_5);
      batch.read('2', partitionKey: pk1.pk);
      batch.create(doc1_2);
      batch.create(doc1_6);

      final resp = await batch.execute();
      expect(resp.success, isFalse);
      expect(resp.length, equals(batch.operations.length));

      final results = resp.results.toList();

      expect(results[0].success, isTrue);
      expect(results[0].item, isNotNull);
      expect(results[0].item!.id, equals(doc1_4.id));

      expect(results[1].success, isTrue);
      expect(results[1].item, isNotNull);
      expect(results[1].item!.id, equals(doc1_5.id));

      expect(results[2].success, isTrue);
      expect(results[2].item, isNotNull);
      expect(results[2].item!.id, equals(doc1_2.id));

      expect(results[3].success, isFalse);
      expect(results[3].item, isNull);

      expect(results[4].success, isTrue);
      expect(results[4].item, isNotNull);
      expect(results[4].item!.id, equals(doc1_6.id));

      var doc = await typedContainer.find<TestTypedDocument>(doc1_2.id,
          partitionKey: pk1.pk);
      expect(doc, isNotNull);

      doc = await typedContainer.find<TestTypedDocument>(doc1_4.id,
          partitionKey: pk1.pk);
      expect(doc, isNotNull);

      doc = await typedContainer.find<TestTypedDocument>(doc1_5.id,
          partitionKey: pk1.pk);
      expect(doc, isNotNull);

      doc = await typedContainer.find<TestTypedDocument>(doc1_6.id,
          partitionKey: pk1.pk);
      expect(doc, isNotNull);
    });

    test('Delete', () async {
      var batch =
          typedContainer.prepareBatch<TestTypedDocument>(continueOnError: true);

      batch.delete(doc1_1.id, partitionKey: pk1.pk);
      batch.delete(doc1_2.id, partitionKey: pk1.pk);
      batch.delete(doc1_3.id, partitionKey: pk1.pk);
      batch.delete(doc1_4.id, partitionKey: pk1.pk);
      batch.delete(doc1_5.id, partitionKey: pk1.pk);
      batch.delete(doc1_6.id, partitionKey: pk1.pk);

      final resp = await batch.execute();
      expect(resp.success, isTrue);
      expect(resp.length, equals(batch.operations.length));

      for (var res in resp.results) {
        expect(res.success, isTrue);
        expect(res.item, isNull);
      }

      var doc = await typedContainer.find<TestTypedDocument>(doc1_2.id,
          partitionKey: pk1.pk);
      expect(doc, isNull);

      doc = await typedContainer.find<TestTypedDocument>(doc1_6.id,
          partitionKey: pk1.pk);
      expect(doc, isNull);
    });

    test('Create - in different partition key ranges', () async {
      var batch =
          typedContainer.prepareBatch<TestTypedDocument>(isAtomic: true);

      batch.create(doc1_1);
      batch.create(doc1_2);
      batch.create(doc2_2);
      batch.read('2', partitionKey: pk1.pk);
      batch.read('2', partitionKey: pk2.pk);

      try {
        await batch.execute();
        throw Exception('The request did not fail');
      } on PartitionKeyException catch (ex) {
        expect(ex.toString().toLowerCase(), contains('several partition key'));
      }

      var doc = await typedContainer.find<TestTypedDocument>(doc1_1.id,
          partitionKey: pk1.pk);
      expect(doc, isNull);

      doc = await typedContainer.find<TestTypedDocument>(doc1_2.id,
          partitionKey: pk1.pk);
      expect(doc, isNull);

      doc = await typedContainer.find<TestTypedDocument>(doc2_2.id,
          partitionKey: pk2.pk);
      expect(doc, isNull);
    });

    test('Create - in same partition key range with different partition key',
        () async {
      var batch =
          typedContainer.prepareBatch<TestTypedDocument>(isAtomic: true);

      batch.create(doc1_1);
      batch.create(doc1_2);
      batch.create(doc3_2);
      batch.read('2', partitionKey: pk1.pk);
      batch.read('2', partitionKey: pk3.pk);

      try {
        await batch.execute();
        throw Exception('The request did not fail');
      } on BadRequestException catch (ex) {
        expect(ex.toString().toLowerCase(),
            contains('different partition key values'));
      }

      var doc = await typedContainer.find<TestTypedDocument>(doc1_1.id,
          partitionKey: pk1.pk);
      expect(doc, isNull);

      doc = await typedContainer.find<TestTypedDocument>(doc1_2.id,
          partitionKey: pk1.pk);
      expect(doc, isNull);

      doc = await typedContainer.find<TestTypedDocument>(doc2_2.id,
          partitionKey: pk2.pk);
      expect(doc, isNull);
    });
  });
}
