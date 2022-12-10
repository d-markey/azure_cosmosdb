import 'package:test/test.dart';

import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';

import '../classes/test_helpers.dart';

void main() async {
  final cosmosDB = await getTestInstance();
  if (cosmosDB != null) {
    run(cosmosDB);
  }
}

void run(CosmosDbServer cosmosDB) {
  final user = CosmosDbUser('UserID');
  final otherUser = CosmosDbUser('Other');

  late CosmosDbDatabase database;

  setUpAll(() async {
    database = await cosmosDB.databases.create(getTempName());
  });

  tearDownAll(() async {
    await cosmosDB.databases.delete(database);
  });

  test('List users before creation', () async {
    expect(await database.users.list(), isEmpty);
  });

  test('Load user info before creation', () async {
    expect(await database.users.find(user.id), isNull);

    await expectLater(
      database.users.find(user.id, throwOnNotFound: true),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('Add user', () async {
    final created = await database.users.add(user);
    expect(created, isNotNull);
    expect(created.id, equals(user.id));

    final loaded = await database.users.find(user.id);
    expect(loaded, isNotNull);
    expect(loaded!.id, equals(user.id));

    final list = await database.users.list();
    expect(list.length, equals(1));
    expect(list.first.id, equals(user.id));
  });

  test('Add existing user', () async {
    expect(await database.users.find(user.id), isNotNull);

    await expectLater(
      database.users.add(CosmosDbUser(user.id)),
      throwsA(isA<ConflictException>()),
    );
  });

  test('Add other user', () async {
    final created = await database.users.add(otherUser);
    expect(created, isNotNull);
    expect(created.id, equals(otherUser.id));

    final loaded = await database.users.find(otherUser.id);
    expect(loaded, isNotNull);
    expect(loaded!.id, equals(otherUser.id));

    final list = await database.users.list();
    expect(list.length, equals(2));
    expect(list.any((u) => u.id == user.id), isTrue);
    expect(list.any((u) => u.id == otherUser.id), isTrue);
  });

  test('Delete user', () async {
    expect(await database.users.find(user.id), isNotNull);
    expect(await database.users.delete(user.id), isTrue);

    expect(await database.users.find(user.id), isNull);
    expect(await database.users.delete(user.id), isTrue);

    await expectLater(
      database.users.delete(user.id, throwOnNotFound: true),
      throwsA(isA<NotFoundException>()),
    );

    final list = await database.users.list();
    expect(list.length, equals(1));
    expect(list.any((u) => u.id == user.id), isFalse);
    expect(list.any((u) => u.id == otherUser.id), isTrue);
  });
}
