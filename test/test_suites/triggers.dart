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

  test('List triggers', () async {
    var triggers = await container.triggers.list();
    expect(triggers, isEmpty);
  });

  test('Create/delete/list triggers', () async {
    var triggers = await container.triggers.list();
    expect(triggers, isEmpty);

    final trigger = CosmosDbTrigger(
      'test_trigger',
      'function f() {}',
      CosmosDbTriggerType.pre,
      CosmosDbTriggerOperation.create,
    );

    final res = await container.triggers.create(trigger);
    expect(res.id, equals(trigger.id));
    expect(res.body, equals(trigger.body));

    triggers = await container.triggers.list();
    expect(triggers, hasLength(1));
    expect(triggers.first.id, equals(trigger.id));
    expect(triggers.first.body, equals(trigger.body));

    await container.triggers.delete(res);

    triggers = await container.triggers.list();
    expect(triggers, isEmpty);
  });

  test('Create/update/delete/list triggers', () async {
    var triggers = await container.triggers.list();
    expect(triggers, isEmpty);

    final trigger = CosmosDbTrigger(
      'test_trigger',
      'function f() {}',
      CosmosDbTriggerType.pre,
      CosmosDbTriggerOperation.create,
    );

    final res = await container.triggers.create(trigger);
    expect(res.id, equals(trigger.id));
    expect(res.body, equals(trigger.body));

    triggers = await container.triggers.list();
    expect(triggers, hasLength(1));
    expect(triggers.first.id, equals(trigger.id));
    expect(triggers.first.body, equals(trigger.body));

    res.setBody('function f() {/*do nothing*/}');

    final upd = await container.triggers.update(res);
    expect(upd.id, equals(res.id));
    expect(upd.body, equals(res.body));

    triggers = await container.triggers.list();
    expect(triggers, hasLength(1));
    expect(triggers.first.id, equals(trigger.id));
    expect(triggers.first.body, isNot(equals(trigger.body)));
    expect(triggers.first.body, equals(res.body));

    await container.triggers.delete(res);

    triggers = await container.triggers.list();
    expect(triggers, isEmpty);
  });

  test('Execute trigger - pre-create', () async {
    final autoTsTrigger = CosmosDbTrigger(
      'auto_ts',
      '''
function autoTimestamp() {
  var context = getContext();
  var request = context.getRequest();

  // item to be created in the current operation
  var itemToCreate = request.getBody();

  // validate properties
  if (!("timestamp" in itemToCreate)) {
    var ts = new Date();
    itemToCreate["timestamp"] = ts.getTime();
  }

  // update the item that will be created
  request.setBody(itemToCreate);
}''',
      CosmosDbTriggerType.pre,
      CosmosDbTriggerOperation.create,
    );

    final secondaryTrigger = CosmosDbTrigger(
      'secondary',
      '''
function test() {
  var context = getContext();
  var request = context.getRequest();

  // item to be created in the current operation
  var itemToCreate = request.getBody();

  // validate properties
  if (!("secondary" in itemToCreate)) {
    itemToCreate["secondary"] = true;
  }

  // update the item that will be created
  request.setBody(itemToCreate);
}''',
      CosmosDbTriggerType.pre,
      CosmosDbTriggerOperation.create,
    );

    await Future.wait([
      container.triggers.create(autoTsTrigger),
      container.triggers.create(secondaryTrigger),
    ]);

    try {
      final item = Document('DOC1', {'Payload': 'Item to create'});
      final res = await container.add(
        item,
        triggerOptions: TriggerOption(preInclude: [autoTsTrigger.id]),
      );
      expect(res.getProp('timestamp'), isA<int>());
      expect(res.getProp('secondary'), isNull);

      final secItem = Document('DOC2', {'Payload': 'Item to create'});
      final secRes = await container.add(
        secItem,
        triggerOptions: TriggerOption(preInclude: [secondaryTrigger.id]),
      );
      expect(secRes.getProp('timestamp'), isNull);
      expect(secRes.getProp('secondary'), isA<bool>());
    } finally {
      await Future.wait([
        container.triggers.delete(autoTsTrigger),
        container.triggers.delete(secondaryTrigger),
      ]);
    }
  });
}
