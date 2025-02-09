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

  test('List stored procedures', () async {
    final sprocs = await container.sprocs.list();
    expect(sprocs, isEmpty);
  });

  test('Create/delete/list procedures', () async {
    final sproc = CosmosDbSproc('test_proc', '''
function f(prefix) {
  var collection = getContext().getCollection();

  // Query documents and take 1st item.
  var isAccepted = collection.queryDocuments(
    collection.getSelfLink(),
    'SELECT * FROM root r',
    function (err, feed, options) {
      if (err) throw err;
      
      getContext().getResponse().setBody(
        (!feed || !feed.length)
          ? 'no docs found' // feed is empty
          : JSON.stringify({ prefix: prefix, feed: feed[0] }) // take 1st element
      );
    }
  );
  
  if (!isAccepted) throw new Error('The query was not accepted by the server.');
}
''');

    final res = await container.sprocs.create(sproc);
    expect(res.id, equals(sproc.id));
    expect(res.body, equals(sproc.body));

    try {
      var sprocs = await container.sprocs.list();
      expect(sprocs, hasLength(1));
      expect(sprocs.first.id, equals(sproc.id));
      expect(sprocs.first.body, equals(sproc.body));

      await container.sprocs.delete(sproc);

      sprocs = await container.sprocs.list();
      expect(sprocs, isEmpty);
    } catch (_) {
      await container.sprocs.delete(sproc);
      rethrow;
    }
  });

  test('Create/update/delete/list procedures', () async {
    final sproc = CosmosDbSproc('test_proc', '''
function f(prefix) {
  var collection = getContext().getCollection();

  // Query documents and take 1st item.
  var isAccepted = collection.queryDocuments(
    collection.getSelfLink(),
    'SELECT * FROM root r',
    function (err, feed, options) {
      if (err) throw err;
      
      getContext().getResponse().setBody(
        (!feed || !feed.length)
          ? 'no docs found' // feed is empty
          : JSON.stringify({ prefix: prefix, feed: feed[0] }) // take 1st element
      );
    }
  );
  
  if (!isAccepted) throw new Error('The query was not accepted by the server.');
}
''');

    final res = await container.sprocs.create(sproc);
    expect(res.id, equals(sproc.id));
    expect(res.body, equals(sproc.body));

    try {
      var sprocs = await container.sprocs.list();
      expect(sprocs, hasLength(1));
      expect(sprocs.first.id, equals(sproc.id));
      expect(sprocs.first.body, equals(sproc.body));

      res.setBody(
          'function f(prefix) { getContext().getResponse().setBody(prefix + \': ok\'); }');

      final upd = await container.sprocs.update(res);
      expect(upd.id, equals(res.id));
      expect(upd.body, equals(res.body));

      sprocs = await container.sprocs.list();
      expect(sprocs, hasLength(1));
      expect(sprocs.first.id, equals(sproc.id));
      expect(sprocs.first.body, isNot(equals(sproc.body)));
      expect(sprocs.first.body, equals(res.body));

      await container.sprocs.delete(sproc);

      sprocs = await container.sprocs.list();
      expect(sprocs, isEmpty);
    } catch (_) {
      await container.sprocs.delete(sproc);
      rethrow;
    }
  });

  test('Execute procedure - raw', () async {
    final sproc = CosmosDbSproc('test_proc', '''
function f(prefix) {
  getContext().getResponse().setBody({ 'res': `Response for prefix "\${prefix}"` });
}
''');
    try {
      await container.sprocs.create(sproc);
      final res = await container.rawExec(sproc, arguments: ['TEST']);
      expect(res, isA<Map>());
      res as Map;
      expect(res, contains('res'));
      expect(res['res'], 'Response for prefix "TEST"');
    } finally {
      await container.sprocs.delete(sproc);
    }
  });

  test('Execute procedure - typed', () async {
    final sproc = CosmosDbSproc('test_proc', '''
function f(prefix) {
  getContext().getResponse().setBody({ 'id': prefix, 'status': 'OK' });
}
''');

    try {
      await container.sprocs.create(sproc);
      final res = await container.exec<Document>(sproc, arguments: ['TEST']);
      expect(res.id, 'TEST');
      expect(res.getProp('id'), 'TEST');
      expect(res.getProp('status'), 'OK');
    } finally {
      await container.sprocs.delete(sproc);
    }
  });

  test('Execute procedure - many typed', () async {
    final sproc = CosmosDbSproc('test_proc', '''
function f(count) {
  res = [];
  for (var i = 0; i < count; i++) {
    res.push({ 'id': `ID\${i}`, 'msg': `Response #\${i+1}`});
  }
  getContext().getResponse().setBody(res);
}
''');

    try {
      await container.sprocs.create(sproc);
      final res =
          (await container.execMany<Document>(sproc, arguments: [3])).toList();
      expect(res[0].getProp('id'), 'ID0');
      expect(res[0].getProp('msg'), 'Response #1');
      expect(res[1].getProp('id'), 'ID1');
      expect(res[1].getProp('msg'), 'Response #2');
      expect(res[2].getProp('id'), 'ID2');
      expect(res[2].getProp('msg'), 'Response #3');
    } finally {
      await container.sprocs.delete(sproc);
    }
  });

  test('Execute procedure - error in user code', () async {
    final sproc = CosmosDbSproc('test_proc', '''
function my_func(prefix) {
  function raise_error() {
    throw new Error(`Intended exception (prefix = "\${prefix}")`);
  }

  raise_error();
}
''');
    try {
      await container.sprocs.create(sproc);
      await container.rawExec(sproc, arguments: ['TEST']);
      throw Exception('Unexpected success');
    } on SprocException catch (ex) {
      // ex.message contains the message from the original response
      expect(ex.message, contains('Intended exception (prefix = \\"TEST\\")'));
      expect(ex.errors, hasLength(greaterThanOrEqualTo(1)));
      final err = ex.errors.first;
      // err.message contains the message (decoded from JSON)
      expect(err.message, contains('Intended exception (prefix = "TEST")'));
      expect(err.stackTrace, contains(contains('my_func')));
      expect(err.stackTrace, contains(contains('raise_error')));
    } finally {
      await container.sprocs.delete(sproc);
    }
  });
}
