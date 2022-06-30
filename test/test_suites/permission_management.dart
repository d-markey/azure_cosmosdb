import 'package:http/http.dart';
import 'package:test/test.dart';

import 'package:azure_cosmosdb/azure_cosmosdb.dart' as cosmos_db;

import '../classes/test_document.dart';
import '../classes/cosmosdb_test_instance.dart';

void main() async {
  final httpClient = cosmos_db.DebugHttpClient();
  final cosmosDB = getTestInstance(httpClient);

  try {
    await cosmosDB.databases.list();
  } catch (e) {
    test('! COSMOS DB IS OFFLINE - TESTS HAVE BEEN DISABLED', () {
      print('Exception: $e');
    });
    return;
  }

  run(cosmosDB, httpClient);
}

void run(cosmos_db.Instance cosmosDB, Client httpClient) {
  final cosmos_db.User user = cosmos_db.User('UserID');

  final permName = '${user.id}-items-perm';
  final collName = 'items';

  late cosmos_db.Database database;
  late String collectionUrl;

  setUpAll(() async {
    database = await cosmosDB.databases
        .create('test_${DateTime.now().millisecondsSinceEpoch}');
    await database.users.add(user);
    database.registerBuilder<TestDocument>(TestDocument.fromJson);
    final collection =
        await database.collections.create(collName, partitionKeys: ['/id']);
    collectionUrl = collection.url;
    await collection.add(TestDocument('1', 'TEST #1', [1, 2, 3]));
    await collection.add(TestDocument('2', 'TEST #2', [2, 3, 5]));
  });

  tearDownAll(() async {
    await cosmosDB.databases.delete(database);
  });

  test('List user permissions before creation', () async {
    expect(await database.users.permissions.list(user), isEmpty);

    await expectLater(
      database.users.permissions.get(user, permName),
      throwsA(isA<cosmos_db.NotFoundException>()),
    );
  });

  test('Grant READ permission on collection', () async {
    try {
      final granted = await database.users.permissions.grant(
        user,
        cosmos_db.Permission(
          permName,
          cosmos_db.PermissionMode.read,
          collectionUrl,
        ),
      );
      expect(granted, isNotNull);
      expect(granted.token, isNotNull);
    } on cosmos_db.Exception catch (ex) {
      print(ex.message);
    }
  });

  test('Read doc with read-only permission', () async {
    final readOnly = await database.users.permissions.get(user, permName);
    expect(readOnly, isNotNull);
    expect(readOnly!.token, isNotNull);

    final roColl = await database.collections.open(collName)
      ..usePermission(readOnly);

    final doc = await roColl.find<TestDocument>('1');
    expect(doc, isNotNull);
    expect(doc!.label, equals('TEST #1'));
  });

  test('Write doc with read-only permission', () async {
    final readOnly = await database.users.permissions.get(user, permName);
    expect(readOnly, isNotNull);
    expect(readOnly!.token, isNotNull);

    final roCOll = await database.collections.open(collName)
      ..usePermission(readOnly);

    await expectLater(
      roCOll.add(TestDocument('4', 'TEST #3', [11, 13, 17])),
      throwsA(isA<cosmos_db.ForbiddenException>()),
    );
  });

  test('Upgrade to ALL permission', () async {
    final granted = await database.users.permissions.replace(
      user,
      cosmos_db.Permission(
        permName,
        cosmos_db.PermissionMode.all,
        collectionUrl,
      ),
    );
    expect(granted, isNotNull);
    expect(granted.token, isNotNull);
  });

  test('Read doc with read/write permission', () async {
    final readWrite = await database.users.permissions.get(user, permName);
    expect(readWrite, isNotNull);
    expect(readWrite!.token, isNotNull);

    final rwColl = await database.collections.open(collName)
      ..usePermission(readWrite);

    final doc = await rwColl.find<TestDocument>('1');
    expect(doc, isNotNull);
    expect(doc!.label, equals('TEST #1'));
  });

  test('Write doc with read/write permission', () async {
    final readWrite = await database.users.permissions.get(user, permName);
    expect(readWrite, isNotNull);
    expect(readWrite!.token, isNotNull);

    final rwColl = await database.collections.open(collName)
      ..usePermission(readWrite);

    final doc = await rwColl.add(TestDocument('4', 'TEST #4', [11, 13, 17]));
    expect(doc, isNotNull);
    expect(doc.id, equals('4'));
    expect(doc.label, equals('TEST #4'));
  });

  test('Expired permission', () async {
    final permission = await database.users.permissions.get(user, permName);
    expect(permission, isNotNull);
    expect(permission!.token, isNotNull);

    final coll = await database.collections.open(collName)
      ..usePermission(permission);

    final dbgClient = httpClient as cosmos_db.DebugHttpClient;

    bool extended = false;
    coll.onForbidden = () {
      extended = true;
      dbgClient.forceForbidden = false;
      return database.users.permissions.get(user, permName);
    };

    dbgClient.forceForbidden = true;
    dbgClient.trace = true;
    final doc = await coll.find<TestDocument>('1');
    dbgClient.forceForbidden = false;
    dbgClient.trace = false;

    expect(extended, isTrue);
    expect(doc, isNotNull);
    expect(doc!.id, equals('1'));
  });

  test('Revoke permission', () async {
    expect(await database.users.permissions.revoke(user, permName), isTrue);

    await expectLater(
      database.users.permissions.get(user, permName),
      throwsA(isA<cosmos_db.NotFoundException>()),
    );
  });
}
