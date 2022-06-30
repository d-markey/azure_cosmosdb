import 'package:test/test.dart';

import 'package:azure_cosmosdb/azure_cosmosdb.dart' as cosmos_db;
import 'package:azure_cosmosdb/src/_extensions.dart';

import '../classes/cosmosdb_test_instance.dart';

void main() async {
  allowSelfSignedCertificates();
  final cosmosDB = getTestInstance(cosmos_db.DebugHttpClient());

  try {
    await cosmosDB.databases.list();
  } catch (e) {
    test('! COSMOS DB IS OFFLINE - TESTS HAVE BEEN DISABLED', () {
      print('Exception: $e');
    });
    return;
  }

  run(cosmosDB);
}

void run(cosmos_db.Instance cosmosDB) {
  final dbName = 'test_${DateTime.now().millisecondsSinceEpoch}';

  test('List databases before creation', () async {
    final list = await cosmosDB.databases.list();
    final db = list.singleOrDefault((db) => db.id == dbName);
    expect(db, isNull);
  });

  test('Open a non-existing database fails', () async {
    await expectLater(
      cosmosDB.databases.open(dbName),
      throwsA(isA<cosmos_db.NotFoundException>()),
    );
  });

  test('Delete a non-existing database fails when throwOnNotFound is true',
      () async {
    final database = cosmos_db.Database(cosmosDB, dbName);
    expect(database.exists, isNull);
    await expectLater(
      cosmosDB.databases.delete(database, throwOnNotFound: true),
      throwsA(isA<cosmos_db.NotFoundException>()),
    );
  });

  test('Delete a non-existing database succeeds when throwOnNotFound is false',
      () async {
    final database = cosmos_db.Database(cosmosDB, dbName);
    expect(database.exists, isNull);
    await cosmosDB.databases.delete(database, throwOnNotFound: false);
    expect(database.exists, isFalse);
  });

  test('Create database with openOrCreate()', () async {
    final database = await cosmosDB.databases.openOrCreate(dbName);
    expect(database, isNotNull);
    expect(database.exists, isTrue);
  });

  test('Open database with openOrCreate()', () async {
    final database = await cosmosDB.databases.openOrCreate(dbName);
    expect(database, isNotNull);
    expect(database.exists, isTrue);
  });

  test('Create duplicate database fails', () async {
    await expectLater(
      cosmosDB.databases.create(dbName),
      throwsA(isA<cosmos_db.ConflictException>()),
    );
  });

  test('List databases after creation', () async {
    final list = await cosmosDB.databases.list();
    final db = list.singleOrDefault((db) => db.id == dbName);
    expect(db, isNotNull);
    expect(db?.exists, isTrue);
  });

  test('Delete database', () async {
    final database = await cosmosDB.databases.openOrCreate(dbName);
    expect(database.exists, isTrue);
    await cosmosDB.databases.delete(database);
    expect(database.exists, isFalse);
  });

  test('List databases after deletion', () async {
    final list = await cosmosDB.databases.list();
    final db = list.singleOrDefault((db) => db.id == dbName);
    expect(db, isNull);
  });
}
