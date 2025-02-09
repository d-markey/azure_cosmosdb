import 'package:azure_cosmosdb/azure_cosmosdb.dart';
import 'package:test/test.dart';

import '../classes/test_helpers.dart';

void main() async {
  final cosmosDB = await getTestInstance(preview: true);
  if (cosmosDB != null) {
    run(cosmosDB);
  }
}

void run(CosmosDbServer cosmosDB) {
  final collName = 'items';

  late CosmosDbDatabase database;
  late CosmosDbContainer container;

  Future<CosmosDbContainer> createContainer() async {
    final container = await database.containers
        .create(collName, partitionKey: PartitionKeySpec.id);
    return container;
  }

  setUpAll(() async {
    database = await cosmosDB.databases.create(getTempName());
    container = await createContainer();
  });

  tearDownAll(() async {
    await cosmosDB.databases.delete(database);
  });

  test('List user defined functions', () async {
    var udfs = await container.udfs.list();
    expect(udfs, isEmpty);
  });

  test('Create/delete/list user defined functions', () async {
    var udfs = await container.udfs.list();
    expect(udfs, isEmpty);

    final udf = CosmosDbFunction(
      'test_fn',
      'function f(prefix) { return prefix; }',
    );

    final res = await container.udfs.create(udf);
    expect(res.id, equals(udf.id));
    expect(res.body, equals(udf.body));

    try {
      udfs = await container.udfs.list();
      expect(udfs, hasLength(1));
      expect(udfs.first.id, equals(udf.id));
      expect(udfs.first.body, equals(udf.body));

      await container.udfs.delete(udf);

      udfs = await container.udfs.list();
      expect(udfs, isEmpty);
    } catch (_) {
      await container.udfs.delete(udf);
      rethrow;
    }
  });

  test('Create/update/delete/list user defined functions', () async {
    var udfs = await container.udfs.list();
    expect(udfs, isEmpty);

    final udf = CosmosDbFunction(
      'test_fn',
      'function f(prefix) { return prefix; }',
    );

    final res = await container.udfs.create(udf);
    expect(res.id, equals(udf.id));
    expect(res.body, equals(udf.body));

    try {
      udfs = await container.udfs.list();
      expect(udfs, hasLength(1));
      expect(udfs.first.id, equals(udf.id));
      expect(udfs.first.body, equals(udf.body));

      res.setBody(
        'function f(prefix) { return \'prefix:\' + prefix; }',
      );

      final upd = await container.udfs.update(res);
      expect(upd.id, equals(res.id));
      expect(upd.body, equals(res.body));

      udfs = await container.udfs.list();
      expect(udfs, hasLength(1));
      expect(udfs.first.id, equals(udf.id));
      expect(udfs.first.body, isNot(equals(udf.body)));
      expect(udfs.first.body, equals(res.body));

      await container.udfs.delete(udf);

      udfs = await container.udfs.list();
      expect(udfs, isEmpty);
    } catch (_) {
      await container.udfs.delete(udf);
      rethrow;
    }
  });

  test('Call user defined function from query', () async {
    var udfs = await container.udfs.list();
    expect(udfs, isEmpty);

    final udf = CosmosDbFunction(
      'test_fn',
      'function f(prefix) { return \'prefix:\' + prefix; }',
    );

    final res = await container.udfs.create(udf);
    expect(res.id, equals(udf.id));
    expect(res.body, equals(udf.body));

    try {
      final doc = Document('test#1', {});
      await container.add(doc);
      final query = Query('SELECT udf.test_fn(c.id) FROM c');
      var resultSet = await container.rawQuery(query);
      expect(resultSet, isA<Map>());
      final docs = resultSet['Documents'];
      expect(docs, isA<List>());
      expect(docs, hasLength(1));
      expect(docs.first, isA<Map>());
      expect(docs.first.values.first, equals('prefix:${doc.id}'));

      await container.udfs.delete(udf);

      udfs = await container.udfs.list();
      expect(udfs, isEmpty);

      try {
        resultSet = await container.rawQuery(query);
      } on BadRequestException catch (ex) {
        // expected
        expect(ex.message, contains('function \'test_fn\' is not present'));
      }
    } catch (_) {
      await container.udfs.delete(udf);
      rethrow;
    }
  });
}
