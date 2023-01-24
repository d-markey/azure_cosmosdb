import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';
import 'package:azure_cosmosdb/src/partition/_partition_key_hash_v2.dart';
import 'package:test/test.dart';

import '../classes/test_document_hierarchical_pk.dart';
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
  late final CosmosDbContainer hierarchicalContainer;

  setUpAll(() async {
    database = await cosmosDB.databases.create(getTempName());
    typedContainer = await database.containers.create(
      getTempName('typed'),
      partitionKey: PartitionKeySpec('/t'),
      throughput: CosmosDbThroughput(10000),
    );
    typedContainer
        .registerBuilder<TestTypedDocument>(TestTypedDocument.fromJson);

    if (cosmosDB.features.hierarchicalPartitioning) {
      hierarchicalContainer = await database.containers.create(
        getTempName('hierarchical'),
        partitionKey: PartitionKeySpec.hierarchical(['/tid', '/uid']),
        throughput: CosmosDbThroughput(10000),
      );
      hierarchicalContainer.registerBuilder<TestDocumentHierarchicalPK>(
          TestDocumentHierarchicalPK.fromJson);
    }
  });

  tearDownAll(() async {
    await cosmosDB.databases.delete(database);
  });

  group('Hash PK -', () {
    test('Check PK ranges', () async {
      var pkRanges = await typedContainer.getPkRanges();
      expect(pkRanges, hasLength(greaterThan(1)));

      final pkr1 = pkRanges.findRangeFor(pk1.pk);
      final pkr2 = pkRanges.findRangeFor(pk2.pk);
      final pkr3 = pkRanges.findRangeFor(pk3.pk);
      expect(pkr1, isNot(equals(pkr2)));
      expect(pkr3, equals(pkr1));
    });

    group('Atomic -', () {
      Batch buildAtomicBatch([PartitionKey? pk]) {
        final batch = typedContainer.prepareAtomicBatch(partitionKey: pk);
        expect(batch.isAtomic, isTrue);
        expect(batch.continueOnError, isFalse);
        expect(batch.isCrossPartition, isFalse);
        return batch;
      }

      runTests(buildAtomicBatch);
    });

    group('Non-Atomic - Fail on error -', () {
      // ignore: non_constant_identifier_names
      Batch buildBatch_stopOnError([PartitionKey? pk]) {
        final batch = typedContainer.prepareBatch(
            continueOnError: false, partitionKey: pk);
        expect(batch.isAtomic, isFalse);
        expect(batch.continueOnError, isFalse);
        expect(batch.isCrossPartition, isFalse);
        return batch;
      }

      runTests(buildBatch_stopOnError);
    });

    group('Non-Atomic - Continue on error -', () {
      // ignore: non_constant_identifier_names
      Batch buildBatch_ignoreErrors([PartitionKey? pk]) {
        final batch = typedContainer.prepareBatch(
            continueOnError: true, partitionKey: pk);
        expect(batch.isAtomic, isFalse);
        expect(batch.continueOnError, isTrue);
        expect(batch.isCrossPartition, isFalse);
        return batch;
      }

      runTests(buildBatch_ignoreErrors);
    });

    group('Cross-partition -', () {
      Batch buildCrossPartitionBatch([PartitionKey? pk]) {
        final batch =
            typedContainer.prepareCrossPartitionBatch(partitionKey: pk);
        expect(batch.isAtomic, isFalse);
        expect(batch.continueOnError, isTrue);
        expect(batch.isCrossPartition, isTrue);
        return batch;
      }

      runTests(buildCrossPartitionBatch);
    });
  });

  group('MultiHash PK -', () {
    test('Check PK ranges', () async {
      var pkRanges = await hierarchicalContainer.getPkRanges();
      expect(pkRanges, hasLength(greaterThan(1)));

      final pkr1A = pkRanges.findRangeFor(pk1A.pk);
      final pkr1B = pkRanges.findRangeFor(pk1B.pk);
      final pkr2A = pkRanges.findRangeFor(pk2A.pk);
      expect(pkr1A, isNot(equals(pkr2A)));
      expect(pkr1A, equals(pkr1B));
    });

    group('Atomic -', () {
      Batch buildAtomicBatch([PartitionKey? pk]) {
        final batch =
            hierarchicalContainer.prepareAtomicBatch(partitionKey: pk);
        expect(batch.isAtomic, isTrue);
        expect(batch.continueOnError, isFalse);
        expect(batch.isCrossPartition, isFalse);
        return batch;
      }

      runHierarchicalTests(buildAtomicBatch);
    });

    group('Non-Atomic - Fail on error -', () {
      // ignore: non_constant_identifier_names
      Batch buildBatch_stopOnError([PartitionKey? pk]) {
        final batch = hierarchicalContainer.prepareBatch(
            continueOnError: false, partitionKey: pk);
        expect(batch.isAtomic, isFalse);
        expect(batch.continueOnError, isFalse);
        expect(batch.isCrossPartition, isFalse);
        return batch;
      }

      runHierarchicalTests(buildBatch_stopOnError);
    });

    group('Non-Atomic - Continue on error -', () {
      // ignore: non_constant_identifier_names
      Batch buildBatch_ignoreErrors([PartitionKey? pk]) {
        final batch = hierarchicalContainer.prepareBatch(
            continueOnError: true, partitionKey: pk);
        expect(batch.isAtomic, isFalse);
        expect(batch.continueOnError, isTrue);
        expect(batch.isCrossPartition, isFalse);
        return batch;
      }

      runHierarchicalTests(buildBatch_ignoreErrors);
    });

    group('Cross-partition -', () {
      Batch buildCrossPartitionBatch([PartitionKey? pk]) {
        final batch =
            hierarchicalContainer.prepareCrossPartitionBatch(partitionKey: pk);
        expect(batch.isAtomic, isFalse);
        expect(batch.continueOnError, isTrue);
        expect(batch.isCrossPartition, isTrue);
        return batch;
      }

      runHierarchicalTests(buildCrossPartitionBatch);
    });
  }, skip: !cosmosDB.features.hierarchicalPartitioning);
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

class HierarchicalPKInfo {
  HierarchicalPKInfo(this.value)
      : pk = PartitionKey.hierarchical(value),
        hash = PartitionKeyHashV2.hierarchical(value);

  final List<String> value;
  final PartitionKey pk;
  final PartitionKeyHashV2 hash;
}

final pk1A = HierarchicalPKInfo(['1', 'A']);
final pk1B = HierarchicalPKInfo(['1', 'B']);
final pk2A = HierarchicalPKInfo(['2', 'A']);

// ignore: no_leading_underscores_for_local_identifiers, non_constant_identifier_names
final _300 = Iterable<int>.generate(300);

void checkResult(BatchOperationResult res, int statusCode, [dynamic expected]) {
  final item = res.item;
  if (HttpStatusCode.isSuccess(statusCode)) {
    expect(res.isSuccess, isTrue);
    if (expected == null) {
      expect(item, isNull);
    } else {
      expect(item, isNotNull);
      if (expected is String) {
        expect(item!.id, equals(expected));
      } else {
        checkDocument(item!, expected);
      }
    }
  } else {
    expect(res.isSuccess, isFalse);
    expect(res.statusCode, equals(statusCode));
    expect(item, isNull);
  }
}

void runTests(Batch Function([PartitionKey?]) buildTestBatch) {
  final doc1_1 = TestTypedDocument('1', pk1.value, 'Positive', [1, 2, 3, 4]);
  final doc1_2 = TestTypedDocument('2', pk1.value, 'Prime', [2, 3, 5, 7]);
  final doc1_3 = TestTypedDocument('3', pk1.value, 'Even', [2, 4, 6, 8]);
  final doc1_4 = TestTypedDocument('4', pk1.value, 'Odd', [3, 5, 7, 9]);
  final doc1_5 = TestTypedDocument('5', pk1.value, 'Zero', [0, 0, 0, 0]);
  final doc1_6 =
      TestTypedDocument('6', pk1.value, 'Negative', [-1, -2, -3, -4]);

  final doc2_2 = TestTypedDocument('2', pk2.value, 'Prime', [2, 3, 5, 7]);

  final doc3_2 = TestTypedDocument('2', pk3.value, 'Prime', [2, 3, 5, 7]);

  test('Create', () async {
    final batch = buildTestBatch(pk1.pk);

    batch.create(doc1_1);
    batch.create(doc1_2);
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
    batch.create(doc1_2); // conflict
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

  test('Replace', () async {
    final batch = buildTestBatch();

    batch.create(TestTypedDocument('1', 'XX', 'Create #1', [1]));
    batch.create(TestTypedDocument('2', 'XX', 'Create #2', [2]));
    var resp = await batch.execute();
    expect(resp.isSuccess, isTrue);

    var results = resp.results.toList();
    expect(resp.length, equals(batch.length));

    checkResult(results[0], HttpStatusCode.ok,
        TestTypedDocument('1', 'XX', 'Create #1', [1]));
    checkResult(results[1], HttpStatusCode.ok,
        TestTypedDocument('2', 'XX', 'Create #2', [2]));

    batch.recycle();
    batch.replace(TestTypedDocument('1', 'XX', 'Replace #1', [1, 3]));
    batch.replace(TestTypedDocument('2', 'XX', 'Replace #2', [2, 4]));
    resp = await batch.execute();
    expect(resp.isSuccess, isTrue);

    results = resp.results.toList();
    expect(resp.length, equals(batch.length));

    checkResult(results[0], HttpStatusCode.ok,
        TestTypedDocument('1', 'XX', 'Replace #1', [1, 3]));
    checkResult(results[1], HttpStatusCode.ok,
        TestTypedDocument('2', 'XX', 'Replace #2', [2, 4]));

    batch.recycle();
    batch.delete('1', partitionKey: PartitionKey('XX'));
    batch.delete('2', partitionKey: PartitionKey('XX'));
    resp = await batch.execute();
    expect(resp.isSuccess, isTrue);
  });

  test('Upsert', () async {
    final batch = buildTestBatch();

    batch.upsert(TestTypedDocument('1', 'XX', 'Create #1', [1]));
    batch.upsert(TestTypedDocument('2', 'XX', 'Create #2', [2]));
    var resp = await batch.execute();
    expect(resp.isSuccess, isTrue);

    var results = resp.results.toList();
    expect(resp.length, equals(batch.length));

    checkResult(results[0], HttpStatusCode.ok,
        TestTypedDocument('1', 'XX', 'Create #1', [1]));
    checkResult(results[1], HttpStatusCode.ok,
        TestTypedDocument('2', 'XX', 'Create #2', [2]));

    batch.recycle();
    batch.upsert(TestTypedDocument('1', 'XX', 'Update #1', [1, 1]));
    batch.upsert(TestTypedDocument('3', 'XX', 'Create #3', [3]));
    resp = await batch.execute();
    expect(resp.isSuccess, isTrue);

    results = resp.results.toList();
    expect(resp.length, equals(batch.length));

    checkResult(results[0], HttpStatusCode.ok,
        TestTypedDocument('1', 'XX', 'Update #1', [1, 1]));
    checkResult(results[1], HttpStatusCode.ok,
        TestTypedDocument('3', 'XX', 'Create #3', [3]));

    batch.recycle();
    batch.delete('1', partitionKey: PartitionKey('XX'));
    batch.delete('2', partitionKey: PartitionKey('XX'));
    batch.delete('3', partitionKey: PartitionKey('XX'));
    resp = await batch.execute();
    expect(resp.isSuccess, isTrue);
  });

  test('Patch', () async {
    final batch = buildTestBatch();

    batch.create(TestTypedDocument('1', 'XX', 'Create #1', [1]));
    batch.create(TestTypedDocument('2', 'XX', 'Create #2', [2]));
    var resp = await batch.execute();
    expect(resp.isSuccess, isTrue);

    var results = resp.results.toList();
    expect(resp.length, equals(batch.length));

    checkResult(results[0], HttpStatusCode.ok,
        TestTypedDocument('1', 'XX', 'Create #1', [1]));
    checkResult(results[1], HttpStatusCode.ok,
        TestTypedDocument('2', 'XX', 'Create #2', [2]));

    batch.recycle();
    var patch1 =
        batch.patch<TestTypedDocument>('1', partitionKey: PartitionKey('XX'));
    patch1.set('/l', 'Patched #1');
    patch1.set('/d', [1, 2, 3]);
    patch1.increment('/d/0');
    patch1.decrement('/d/2');

    var patch2 =
        batch.patch<TestTypedDocument>('2', partitionKey: PartitionKey('XX'));
    patch2.set('/l', 'Patched #2');
    patch2.set('/d/0', 8);
    patch2.add('/d/-', -1);

    resp = await batch.execute();
    expect(resp.isSuccess, isTrue);

    results = resp.results.toList();
    expect(resp.length, equals(batch.length));

    // >>> COSMOS DB bug when using incr patch operations on array items
    // >>> see https://github.com/Azure/azure-cosmos-dotnet-v3/issues/3659
    checkResult(results[0], HttpStatusCode.ok,
        TestTypedDocument('1', 'XX', 'Patched #1', [2, 1, 1, 2, 3]));
    // <<< once MS has fixed the bug, the array should contain [2, 2, 2]
    // <<< COSMOS DB bug when using incr patch operations on array items

    checkResult(results[1], HttpStatusCode.ok,
        TestTypedDocument('2', 'XX', 'Patched #2', [8, -1]));

    batch.recycle();
    batch.delete('1', partitionKey: PartitionKey('XX'));
    batch.delete('2', partitionKey: PartitionKey('XX'));
    resp = await batch.execute();
    expect(resp.isSuccess, isTrue);
  });

  test('100+ operations', () async {
    final batch = buildTestBatch();

    int count = 0;
    try {
      for (var i in _300) {
        batch.create(TestTypedDocument('OK-$i', pk1.value, 'Label $i', [i]));
        count++;
      }
      expect(batch.operations, hasLength(300));
      if (batch.isAtomic) {
        throw Exception('Atomic batch must be limited to 100 operations');
      }
    } on ApplicationException catch (ex) {
      if (!batch.isAtomic) {
        // non-atomic implementations must succeed
        rethrow;
      } else {
        // atomic must fail
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
      expect(batch.operations, hasLength(300));
      if (batch.isAtomic) {
        throw Exception('Atomic batch must be limited to 100 operations');
      }
    } on ApplicationException catch (ex) {
      if (!batch.isAtomic) {
        // non-atomic implementations must succeed
        rethrow;
      } else {
        // atomic must fail
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
        // atomic batch: all operations fail, first errored op with conflict status,
        // all other ops with failedDependency status.
        if (ok && collide(i)) {
          checkResult(results[i], HttpStatusCode.conflict);
          ok = false;
        } else {
          checkResult(results[i], HttpStatusCode.failedDependency);
        }
      } else if (batch.continueOnError) {
        // continue on error batch: only invalid operations fail with conflict status,
        // all other ops succeed.
        if (collide(i)) {
          checkResult(results[i], HttpStatusCode.conflict);
        } else {
          checkResult(results[i], HttpStatusCode.ok, 'OK-$i');
          batch.delete('OK-$i', partitionKey: pk1.pk);
        }
      } else {
        // stop on error batch: ops succeed up to the first errored op which fails with
        // conflict status, then subsequent ops fail with failedDependency status.
        if (!ok) {
          checkResult(results[i], HttpStatusCode.failedDependency);
        } else if (collide(i)) {
          checkResult(results[i], HttpStatusCode.conflict);
          ok = false;
        } else {
          checkResult(results[i], HttpStatusCode.ok, 'OK-$i');
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
      expect(resp.isSuccess, batch.isCrossPartition ? isTrue : isFalse);

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
      expect(resp.isSuccess, batch.isCrossPartition ? isTrue : isFalse);
    } on PartitionKeyException {
      if (batch.isCrossPartition) {
        // cross-partition implementation must succeed
        rethrow;
      } else {
        // other implementations must fail with a PartitionKeyException
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
      expect(resp.isSuccess, batch.isCrossPartition ? isTrue : isFalse);

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
      expect(resp.isSuccess, batch.isCrossPartition ? isTrue : isFalse);
    } on PartitionKeyException {
      if (batch.isCrossPartition) {
        // cross-partition implementation must succeed
        rethrow;
      } else {
        // other implementations must fail with a PartitionKeyException
      }
    }
  });
}

void runHierarchicalTests(Batch Function([PartitionKey?]) buildTestBatch) {
  final doc1A_1 = TestDocumentHierarchicalPK(
      '1', pk1A.value[0], pk1A.value[1], 'Contoso / A / #1');
  final doc1A_2 = TestDocumentHierarchicalPK(
      '2', pk1A.value[0], pk1A.value[1], 'Contoso / A / #2');

  final doc1B_2 = TestDocumentHierarchicalPK(
      '2', pk1B.value[0], pk1B.value[1], 'Contoso / B / #2');

  final doc2A_1 = TestDocumentHierarchicalPK(
      '1', pk2A.value[0], pk2A.value[1], 'Acme / A / #1');

  test('Create', () async {
    final batch = buildTestBatch(pk1A.pk);

    batch.create(doc1A_1);
    batch.create(doc1A_2);
    batch.read<TestDocumentHierarchicalPK>('2');

    var resp = await batch.execute();
    expect(resp.isSuccess, isTrue);

    var results = resp.results.toList();
    expect(results.length, equals(batch.length));

    checkResult(results[0], HttpStatusCode.ok, doc1A_1);
    checkResult(results[1], HttpStatusCode.ok, doc1A_2);

    batch.recycle();
    batch.delete(doc1A_1.id);
    batch.delete(doc1A_2.id);
    resp = await batch.execute();
    expect(resp.isSuccess, isTrue);
  });

  test('Create with multiple partition keys', () async {
    final batch = buildTestBatch();

    try {
      batch.create(doc1A_1);
      batch.upsert(doc1B_2);
      batch.create(doc2A_1);
      batch.read<TestDocumentHierarchicalPK>('1', partitionKey: pk2A.pk);

      var resp = await batch.execute();
      expect(resp.isSuccess, batch.isCrossPartition ? isTrue : isFalse);

      var results = resp.results.toList();
      expect(results.length, equals(batch.length));

      checkResult(results[0], HttpStatusCode.ok, doc1A_1);
      checkResult(results[1], HttpStatusCode.ok, doc1B_2);
      checkResult(results[2], HttpStatusCode.ok, doc2A_1);
      checkResult(results[3], HttpStatusCode.ok, doc2A_1);

      batch.recycle();
      batch.delete(doc1A_1.id, partitionKey: pk1A.pk);
      batch.delete(doc1B_2.id, partitionKey: pk1B.pk);
      batch.delete(doc2A_1.id, partitionKey: pk2A.pk);
      resp = await batch.execute();
      expect(resp.isSuccess, batch.isCrossPartition ? isTrue : isFalse);
    } on PartitionKeyException {
      if (batch.isCrossPartition) {
        // cross-partition implementation must succeed
        rethrow;
      } else {
        // other implementations must fail with a PartitionKeyException
      }
    }
  });
}
