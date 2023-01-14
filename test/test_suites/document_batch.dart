import 'dart:convert';

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

void run(CosmosDbServer cosmosDB) {
  late final CosmosDbDatabase database;
  late final CosmosDbContainer typedContainer;

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

    final pkr1 = pkRanges.findRangeFor(pk1.pk);
    final pkr2 = pkRanges.findRangeFor(pk2.pk);
    final pkr3 = pkRanges.findRangeFor(pk3.pk);
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
    runTests(() => typedContainer.prepareAtomicBatch());
  });

  group('Non-Atomic - Fail on error -', () {
    runTests(() => typedContainer.prepareBatch(continueOnError: false));
  });

  group('Non-Atomic - Continue on error -', () {
    runTests(() => typedContainer.prepareBatch(continueOnError: true));
  });

  group('Cross-partition -', () {
    runTests(() => typedContainer.prepareCrossPartitionBatch());
  });
}

class PKInfo {
  PKInfo(this.value)
      : pk = PartitionKey(value),
        hash = PartitionKeyHashV2.string(value);

  final String value;
  final PartitionKey pk;
  final PartitionKeyHashV2 hash;
}

final pk1 = PKInfo('1');
final pk2 = PKInfo('2');
final pk3 = PKInfo('3');

final doc1_1 = TestTypedDocument('1', pk1.value, 'Positive', [1, 2, 3, 4]);
final doc1_2 = TestTypedDocument('2', pk1.value, 'Prime', [2, 3, 5, 7]);
final doc1_3 = TestTypedDocument('3', pk1.value, 'Even', [2, 4, 6, 8]);
final doc1_4 = TestTypedDocument('4', pk1.value, 'Odd', [3, 5, 7, 9]);
final doc1_5 = TestTypedDocument('5', pk1.value, 'Zero', [0, 0, 0, 0]);
final doc1_6 = TestTypedDocument('6', pk1.value, 'Negative', [-1, -2, -3, -4]);

final doc2_2 = TestTypedDocument('2', pk2.value, 'Prime', [2, 3, 5, 7]);

final doc3_2 = TestTypedDocument('2', pk3.value, 'Prime', [2, 3, 5, 7]);

// ignore: no_leading_underscores_for_local_identifiers, non_constant_identifier_names
final _300 = Iterable<int>.generate(300);

void checkResult(BatchOperationResult res, int statusCode,
    [BaseDocument? doc]) {
  final item = res.item;
  if (HttpStatusCode.isSuccess(statusCode)) {
    expect(res.isSuccess, isTrue);
    if (doc == null) {
      expect(item, isNull);
    } else {
      expect(item, isNotNull);
      expect(item!.id, equals(doc.id));
      if (doc is! DocumentWithId) {
        final json = jsonEncode(item.toJson());
        final expected = jsonEncode(doc.toJson());
        expect(json, equals(expected));
      }
    }
  } else {
    expect(res.isSuccess, isFalse);
    expect(res.statusCode, equals(statusCode));
    expect(item, isNull);
  }
}

void runTests(Batch Function() buildTestBatch) {
  test('Create', () async {
    final batch = buildTestBatch();

    batch.create(doc1_1);
    batch.upsert(doc1_2);
    batch.create(doc1_3);
    batch.read<TestTypedDocument>('2', partitionKey: pk1.pk);

    var resp = await batch.execute();
    expect(resp.isSuccess, isTrue);

    var results = resp.results.toList();
    expect(results.length, equals(batch.length));

    checkResult(results[0], HttpStatusCode.ok, doc1_1);
    checkResult(results[1], HttpStatusCode.ok, doc1_2);
    checkResult(results[2], HttpStatusCode.ok, doc1_3);
    checkResult(results[3], HttpStatusCode.ok, doc1_2);

    batch.recycle();
    batch.delete(doc1_1.id, partitionKey: pk1.pk);
    batch.delete(doc1_2.id, partitionKey: pk1.pk);
    batch.delete(doc1_3.id, partitionKey: pk1.pk);
    resp = await batch.execute();
    expect(resp.isSuccess, isTrue);
  });

  test('Create with conflict', () async {
    final batch = buildTestBatch();

    batch.create(doc1_4);
    batch.create(doc1_2);
    batch.create(doc1_5);
    batch.read<TestTypedDocument>('2', partitionKey: pk1.pk);
    batch.create(doc1_2);
    batch.create(doc1_6);

    var resp = await batch.execute();
    expect(resp.isSuccess, isFalse);

    final results = resp.results.toList();
    expect(resp.length, equals(batch.length));

    if (batch.isAtomic) {
      checkResult(results[0], HttpStatusCode.failedDependency);
      checkResult(results[1], HttpStatusCode.failedDependency);
      checkResult(results[2], HttpStatusCode.failedDependency);
      checkResult(results[3], HttpStatusCode.failedDependency);
    } else {
      checkResult(results[0], HttpStatusCode.ok, doc1_4);
      checkResult(results[1], HttpStatusCode.ok, doc1_2);
      checkResult(results[2], HttpStatusCode.ok, doc1_5);
      checkResult(results[3], HttpStatusCode.ok, doc1_2);
    }

    checkResult(results[4], HttpStatusCode.conflict);

    if (batch.continueOnError) {
      checkResult(results[5], HttpStatusCode.ok, doc1_6);
    } else {
      checkResult(results[5], HttpStatusCode.failedDependency);
    }

    batch.recycle();
    if (!batch.isAtomic) {
      batch.delete(doc1_4.id, partitionKey: pk1.pk);
      batch.delete(doc1_2.id, partitionKey: pk1.pk);
      batch.delete(doc1_5.id, partitionKey: pk1.pk);
      if (batch.continueOnError) {
        batch.delete(doc1_6.id, partitionKey: pk1.pk);
      }
      resp = await batch.execute();
      expect(resp.isSuccess, isTrue);
    }
  });

  test('100+ operations', () async {
    final batch = buildTestBatch();

    int count = 0;
    try {
      for (var i in _300) {
        batch.create(TestTypedDocument('OK-$i', pk1.value, 'Label $i', [i]));
        count++;
      }
      if (batch.isAtomic) {
        throw Exception('Atomic batch cannot have more than 100 operations');
      }
    } on ApplicationException catch (ex) {
      if (!batch.isAtomic) {
        rethrow;
      } else {
        expect(ex.message.toLowerCase(), contains('limited to 100'));
      }
    }

    var resp = await batch.execute();
    expect(resp.isSuccess, isTrue);

    batch.recycle();
    for (var i = 0; i < count; i++) {
      batch.delete('OK-$i', partitionKey: pk1.pk);
    }
    resp = await batch.execute();
    expect(resp.isSuccess, isTrue);
  });

  test('100+ operations with conflict', () async {
    final batch = buildTestBatch();

    bool collide(int i) => (i > 0 && i % 37 == 0) || (197 <= i && i <= 333);

    var count = 0;
    try {
      for (var i in _300) {
        var id = collide(i) ? 0 : i;
        batch.create(TestTypedDocument('OK-$id', pk1.value, 'Label $i', [i]));
        count++;
      }
      if (batch.isAtomic) {
        throw Exception('Atomic batch cannot have more than 100 operations');
      }
    } on ApplicationException catch (ex) {
      if (!batch.isAtomic) {
        rethrow;
      } else {
        expect(ex.message.toLowerCase(), contains('limited to 100'));
      }
    }

    var resp = await batch.execute();
    expect(resp.isSuccess, isFalse);

    var results = resp.results.toList();

    batch.recycle();
    var ok = true;
    for (var i = 0; i < count; i++) {
      if (batch.isAtomic) {
        if (ok && collide(i)) {
          checkResult(results[i], HttpStatusCode.conflict);
          ok = false;
        } else {
          checkResult(results[i], HttpStatusCode.failedDependency);
        }
      } else if (batch.continueOnError) {
        if (collide(i)) {
          checkResult(results[i], HttpStatusCode.conflict);
        } else {
          checkResult(results[i], HttpStatusCode.ok, DocumentWithId('OK-$i'));
          batch.delete('OK-$i', partitionKey: pk1.pk);
        }
      } else {
        if (!ok) {
          checkResult(results[i], HttpStatusCode.failedDependency);
        } else if (collide(i)) {
          checkResult(results[i], HttpStatusCode.conflict);
          ok = false;
        } else {
          checkResult(results[i], HttpStatusCode.ok, DocumentWithId('OK-$i'));
          batch.delete('OK-$i', partitionKey: pk1.pk);
        }
      }
    }

    if (batch.operations.isNotEmpty) {
      resp = await batch.execute();
      expect(resp.isSuccess, isTrue);
    }
  });

  test('Create with multiple partition keys (same range)', () async {
    final batch = buildTestBatch();

    try {
      batch.create(doc1_1);
      batch.upsert(doc3_2);
      batch.create(doc1_2);
      batch.read<TestTypedDocument>('2', partitionKey: pk3.pk);

      var resp = await batch.execute();
      expect(resp.isSuccess, isTrue);

      var results = resp.results.toList();
      expect(results.length, equals(batch.length));

      checkResult(results[0], HttpStatusCode.ok, doc1_1);
      checkResult(results[1], HttpStatusCode.ok, doc3_2);
      checkResult(results[2], HttpStatusCode.ok, doc1_2);
      checkResult(results[3], HttpStatusCode.ok, doc3_2);

      batch.recycle();
      batch.delete(doc1_1.id, partitionKey: pk1.pk);
      batch.delete(doc3_2.id, partitionKey: pk3.pk);
      batch.delete(doc1_2.id, partitionKey: pk1.pk);
      resp = await batch.execute();
      expect(resp.isSuccess, isTrue);
    } on PartitionKeyException {
      if (batch.isCrossPartition) {
        rethrow;
      }
    }
  });

  test('Create with multiple partition keys (different ranges)', () async {
    final batch = buildTestBatch();

    try {
      batch.create(doc1_2);
      batch.upsert(doc3_2);
      batch.create(doc2_2);
      batch.read<TestTypedDocument>('2', partitionKey: pk2.pk);

      var resp = await batch.execute();
      expect(resp.isSuccess, isTrue);

      var results = resp.results.toList();
      expect(results.length, equals(batch.length));

      checkResult(results[0], HttpStatusCode.ok, doc1_2);
      checkResult(results[1], HttpStatusCode.ok, doc3_2);
      checkResult(results[2], HttpStatusCode.ok, doc2_2);
      checkResult(results[3], HttpStatusCode.ok, doc2_2);

      batch.recycle();
      batch.delete(doc1_2.id, partitionKey: pk1.pk);
      batch.delete(doc3_2.id, partitionKey: pk3.pk);
      batch.delete(doc2_2.id, partitionKey: pk2.pk);
      resp = await batch.execute();
      expect(resp.isSuccess, isTrue);
    } on PartitionKeyException {
      if (batch.isCrossPartition) {
        rethrow;
      }
    }
  });
}
