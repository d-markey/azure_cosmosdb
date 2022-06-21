import 'package:azure_cosmosdb/azure_cosmosdb.dart' as cosmosdb;
import 'package:azure_cosmosdb/azure_cosmosdb.dart';
import 'package:azure_cosmosdb/src/_extensions.dart';

import 'package:azure_cosmosdb/src/debug_http_overrides_web.dart'
    if (dart.library.io) 'package:azure_cosmosdb/src/debug_http_overrides_vm.dart';

import 'package:test/test.dart';

const _masterKey =
    'C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==';

void main() async {
  allowSelfSignedCertificates();

  final httpClient = cosmosdb.DebugHttpClient(trace: false);
  final server = cosmosdb.Server(
    'https://localhost:8081',
    masterKey: _masterKey,
    httpClient: httpClient,
  );

  try {
    await server.databases.list();
  } catch (e) {
    test('! COSMOS DB IS OFFLINE - TESTS HAVE BEEN DISABLED', () {
      print('Exception: $e');
    });
    return;
  }

  final dbName = 'test_${DateTime.now().millisecondsSinceEpoch}';

  group('DATABASE MANAGEMENT -', () {
    test('List databases before creation', () async {
      final list = await server.databases.list();
      final db = list.singleOrDefault((db) => db.id == dbName);
      expect(db, isNull);
    });

    test('Open a non-existing database fails', () async {
      expect(server.databases.open(dbName),
          throwsA(isA<cosmosdb.NotFoundException>()));
    });

    test('Delete a non-existing database fails when throwOnNotFound is true',
        () async {
      final database = Database(server.client, dbName);
      expect(database.exists, isNull);
      expect(server.databases.delete(database, throwOnNotFound: true),
          throwsA(isA<cosmosdb.NotFoundException>()));
    });

    test(
        'Delete a non-existing database succeeds when throwOnNotFound is false',
        () async {
      final database = Database(server.client, dbName);
      expect(database.exists, isNull);
      await server.databases.delete(database, throwOnNotFound: false);
      expect(database.exists, isFalse);
    });

    test('Create database with openOrCreate()', () async {
      final database = await server.databases.openOrCreate(dbName);
      expect(database, isNotNull);
      expect(database.exists, isTrue);
    });

    test('Open database with openOrCreate()', () async {
      final database = await server.databases.openOrCreate(dbName);
      expect(database, isNotNull);
      expect(database.exists, isTrue);
    });

    test('Create database with create() fails', () async {
      expect(server.databases.create(dbName),
          throwsA(isA<cosmosdb.ConflictException>()));
    });

    test('List databases after creation', () async {
      final list = await server.databases.list();
      final db = list.singleOrDefault((db) => db.id == dbName);
      expect(db, isNotNull);
      expect(db?.exists, isTrue);
    });

    test('Delete database', () async {
      final database = await server.databases.openOrCreate(dbName);
      expect(database.exists, isTrue);
      await server.databases.delete(database);
      expect(database.exists, isFalse);
    });

    test('List databases after deletion', () async {
      final list = await server.databases.list();
      final db = list.singleOrDefault((db) => db.id == dbName);
      expect(db, isNull);
    });
  });

  group('COLLECTION MANAGEMENT -', () {
    final collName1 = 'test_1';
    final collName2 = 'test_2';

    Database? database;

    setUpAll(() async {
      database = await server.databases.create(dbName);
    });

    tearDownAll(() async {
      await server.databases.delete(database!);
    });

    test('List collections before creation', () async {
      final list = await database!.collections.list();
      final coll =
          list.where((coll) => coll.id == collName1 || coll.id == collName2);
      expect(coll, isEmpty);
    });

    test('Open a non-existing collection fails', () async {
      expect(database!.collections.open(collName1),
          throwsA(isA<cosmosdb.NotFoundException>()));
      expect(database!.collections.open(collName2),
          throwsA(isA<cosmosdb.NotFoundException>()));
    });

    test('Delete a non-existing collection fails when throwOnNotFound is true',
        () async {
      final collection = Collection(database!, collName1);
      expect(collection.exists, isNull);
      expect(database!.collections.delete(collection, throwOnNotFound: true),
          throwsA(isA<cosmosdb.NotFoundException>()));
    });

    test(
        'Delete a non-existing collection succeeds when throwOnNotFound is false',
        () async {
      final collection = Collection(database!, collName1);
      expect(collection.exists, isNull);
      await database!.collections.delete(collection, throwOnNotFound: false);
      expect(collection.exists, isFalse);
    });

    test('Create collection with openOrCreate()', () async {
      final collection = await database!.collections
          .openOrCreate(collName1, partitionKeys: ['/id']);
      expect(collection, isNotNull);
      expect(collection.exists, isTrue);
    });

    test('Open collection with openOrCreate()', () async {
      final collection = await database!.collections.openOrCreate(collName1);
      expect(collection, isNotNull);
      expect(collection.exists, isTrue);
    });

    test('Create collection with create() fails', () async {
      expect(database!.collections.create(collName1, partitionKeys: ['/id']),
          throwsA(isA<cosmosdb.ConflictException>()));
    });

    test('List collections after creation', () async {
      final list = await database!.collections.list();
      final collection = list.singleOrDefault((coll) => coll.id == collName1);
      expect(collection, isNotNull);
      expect(collection?.exists, isTrue);
    });

    test('Delete collection', () async {
      final collection = await database!.collections.openOrCreate(collName1);
      expect(collection.exists, isTrue);
      await database!.collections.delete(collection);
      expect(collection.exists, isFalse);
    });

    test('List collections after deletion', () async {
      final list = await database!.collections.list();
      final collection = list.singleOrDefault((coll) => coll.id == collName1);
      expect(collection, isNull);
    });
  });
}
