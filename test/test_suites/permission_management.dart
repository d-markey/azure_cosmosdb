import 'package:test/test.dart';

import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';

import '../classes/test_document.dart';
import '../classes/test_helpers.dart';

void main() async {
  final cosmosDB = await getTestInstance(preview: true);
  if (cosmosDB != null) {
    run(cosmosDB);
  }
}

void run(CosmosDbServer cosmosDB) {
  final CosmosDbUser user = CosmosDbUser('UserID');

  final permName = '${user.id}-items-perm-$secondsSinceEpoch';
  final collName = 'items';

  late CosmosDbDatabase database;
  late String containerUrl;

  Future<CosmosDbContainer> createContainer() async {
    final container = await database.containers
        .create(collName, partitionKey: PartitionKeySpec.id);
    container.registerBuilder<TestDocument>(TestDocument.fromJson);
    return container;
  }

  Future<CosmosDbContainer> openContainer() async {
    final container = await database.containers.open(collName);
    container.registerBuilder<TestDocument>(TestDocument.fromJson);
    return container;
  }

  setUpAll(() async {
    database = await cosmosDB.databases.create(getTempName());
    final container = await createContainer();
    containerUrl = container.url;
    await container.add(TestDocument('1', 'TEST #1', [1, 2, 3]));
    await container.add(TestDocument('2', 'TEST #2', [2, 3, 5]));

    await database.users.add(user);
  });

  tearDownAll(() async {
    await cosmosDB.databases.delete(database);
  });

  test('List user permissions before creation', () async {
    expect(await database.users.permissions.list(user), isEmpty);

    await expectLater(
      database.users.permissions.get(user, permName),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('Trying to grant a permission with invalid expiry duration must fail',
      () async {
    await expectLater(
        database.users.permissions.grant(
          user,
          CosmosDbPermission(
            permName,
            PermissionMode.read,
            containerUrl,
          ),
          expiry: Duration(days: 366),
        ),
        throwsA(isA<CosmosDbException>()));
  });

  test('Grant READ permission on container', () async {
    final granted = await database.users.permissions.grant(
      user,
      CosmosDbPermission(
        permName,
        PermissionMode.read,
        containerUrl,
      ),
      expiry: Duration(minutes: 30),
    );
    expect(granted, isNotNull);
    expect(granted.token, isNotNull);
  });

  test('Read doc with read-only permission', () async {
    final readOnly = await database.users.permissions.get(user, permName);
    expect(readOnly, isNotNull);
    expect(readOnly!.token, isNotNull);

    final roColl = await openContainer()
      ..usePermission(readOnly);

    final doc = await roColl.find<TestDocument>('1', PartitionKey('1'));
    expect(doc, isNotNull);
    expect(doc!.label, equals('TEST #1'));
  });

  test('Write doc with read-only permission', () async {
    final readOnly = await database.users.permissions.get(user, permName);
    expect(readOnly, isNotNull);
    expect(readOnly!.token, isNotNull);

    final roColl = await openContainer()
      ..usePermission(readOnly);

    await expectLater(
      roColl.add(TestDocument('4', 'TEST #3', [11, 13, 17])),
      throwsA(isA<ForbiddenException>()),
    );
  });

  test('Upgrade to ALL permission', () async {
    final granted = await database.users.permissions.replace(
      user,
      CosmosDbPermission(
        permName,
        PermissionMode.all,
        containerUrl,
      ),
      expiry: Duration(minutes: 15),
    );
    expect(granted, isNotNull);
    expect(granted.token, isNotNull);
  });

  test('Read doc with read/write permission', () async {
    final readWrite = await database.users.permissions.get(user, permName);
    expect(readWrite, isNotNull);
    expect(readWrite!.token, isNotNull);

    final rwColl = await openContainer()
      ..usePermission(readWrite);

    final doc = await rwColl.find<TestDocument>('1', PartitionKey('1'));
    expect(doc, isNotNull);
    expect(doc!.label, equals('TEST #1'));
  });

  test('Write doc with read/write permission', () async {
    final readWrite = await database.users.permissions.get(user, permName);
    expect(readWrite, isNotNull);
    expect(readWrite!.token, isNotNull);

    final rwColl = await openContainer()
      ..usePermission(readWrite);

    final doc = await rwColl.add(TestDocument('4', 'TEST #4', [11, 13, 17]));
    expect(doc, isNotNull);
    expect(doc.id, equals('4'));
    expect(doc.label, equals('TEST #4'));
  });

  test('Expired permission', () async {
    final permission = await database.users.permissions
        .get(user, permName, expiry: Duration(seconds: 600));
    expect(permission, isNotNull);
    expect(permission!.token, isNotNull);

    final coll = await openContainer()
      ..usePermission(permission);

    // permissions have a resolution of 1 second with undocumented minimal
    // delay... to avoid waiting that amount of time in tests, the debug HTTP
    // client is forced into replying with "403 Forbidden" responses.
    cosmosDB.dbgHttpClient?.forceForbidden = true;

    bool handled = false;
    coll.onForbidden = () {
      handled = true;
      // disable forced "403 Forbidden" responses
      cosmosDB.dbgHttpClient?.forceForbidden = false;
      // update the permission
      return database.users.permissions.get(user, permName);
    };

    try {
      final doc = await coll.find<TestDocument>('1', PartitionKey('1'));
      // if the permission was properly refreshed, handled should be true
      // and the document was found
      expect(handled, isTrue);
      expect(doc, isNotNull);
      expect(doc!.id, equals('1'));
    } finally {
      // disable forced "403 Forbidden" responses
      cosmosDB.dbgHttpClient?.forceForbidden = false;
    }
  });

  test('Revoke permission', () async {
    expect(await database.users.permissions.revoke(user, permName), isTrue);

    await expectLater(
      database.users.permissions.get(user, permName),
      throwsA(isA<NotFoundException>()),
    );
  });
}
