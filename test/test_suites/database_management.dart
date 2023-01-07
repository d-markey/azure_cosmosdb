import 'dart:async';

import 'package:azure_cosmosdb/azure_cosmosdb_debug.dart';
import 'package:azure_cosmosdb/src/_internal/_linq_extensions.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

import '../classes/socket_exception_mock.dart' if (dart.library.io) 'dart:io'
    show SocketException;

import '../classes/test_helpers.dart';

void main() async {
  final cosmosDB = await getTestInstance(preview: true);
  if (cosmosDB != null) {
    run(cosmosDB);
  }
}

void run(CosmosDbServer cosmosDB) {
  final dbName = getTempName();

  test('Requests fail when master key and permission are missing', () async {
    final server = CosmosDbServer('https://localhost:8081');
    try {
      await expectLater(
          server.databases.list(), throwsA(isA<UnauthorizedException>()));
    } finally {
      server.dbgHttpClient?.close();
    }
  });

  test('List databases before creation', () async {
    final list = await cosmosDB.databases.list();
    final db = list.singleOrDefault((db) => db.id == dbName);
    expect(db, isNull);
  });

  test('Requests throwing a timeout exception must be retried', () async {
    cosmosDB.dbgHttpClient?.forceException = TimeoutException('Test timeout');
    expect(cosmosDB.dbgHttpClient?.forceException, isNotNull);
    final list = await cosmosDB.databases.list();
    expect(cosmosDB.dbgHttpClient?.forceException, isNull);
    final db = list.singleOrDefault((db) => db.id == dbName);
    expect(db, isNull);
  });

  test('Requests throwing a client exception must be retried', () async {
    cosmosDB.dbgHttpClient?.forceException =
        ClientException('Test client error');
    expect(cosmosDB.dbgHttpClient?.forceException, isNotNull);
    final list = await cosmosDB.databases.list();
    expect(cosmosDB.dbgHttpClient?.forceException, isNull);
    final db = list.singleOrDefault((db) => db.id == dbName);
    expect(db, isNull);
  });

  test(
      'Requests throwing a socket exception must be retried (native platforms only)',
      () async {
    cosmosDB.dbgHttpClient?.forceException =
        SocketException('Test socket error');
    expect(cosmosDB.dbgHttpClient?.forceException, isNotNull);
    final list = await cosmosDB.databases.list();
    expect(cosmosDB.dbgHttpClient?.forceException, isNull);
    final db = list.singleOrDefault((db) => db.id == dbName);
    expect(db, isNull);
  }, testOn: '!js');

  test('Requests throwing other errors must fail', () async {
    final exception = 'No retry ${DateTime.now().millisecondsSinceEpoch}';
    cosmosDB.dbgHttpClient?.forceException = exception;
    expect(cosmosDB.dbgHttpClient?.forceException, isNotNull);
    try {
      await cosmosDB.databases.list();
      throw Exception('The request did not fail');
    } catch (ex) {
      expect(ex, equals(exception));
    }
    expect(cosmosDB.dbgHttpClient?.forceException, isNull);
  });

  test('Open a non-existing database fails', () async {
    await expectLater(
      cosmosDB.databases.open(dbName),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('Delete a non-existing database fails when throwOnNotFound is true',
      () async {
    final database = CosmosDbDatabase(cosmosDB, dbName);
    expect(database.exists, isNull);
    await expectLater(
      cosmosDB.databases.delete(database, throwOnNotFound: true),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('Delete a non-existing database succeeds when throwOnNotFound is false',
      () async {
    final database = CosmosDbDatabase(cosmosDB, dbName);
    expect(database.exists, isNull);
    await cosmosDB.databases.delete(database, throwOnNotFound: false);
    expect(database.exists, isFalse);
  });

  test('Create database with openOrCreate()', () async {
    final database = await cosmosDB.databases.openOrCreate(dbName);
    expect(database, isNotNull);
    expect(database.exists, isTrue);
  });

  test('Create database with openOrCreate() - fixed throuput', () async {
    final database = await cosmosDB.databases
        .openOrCreate(getTempName(), throughput: CosmosDbThroughput(5000));
    expect(database, isNotNull);
    expect(database.exists, isTrue);
    await cosmosDB.databases.delete(database);
  });

  test('Create database with openOrCreate() - auto-scale', () async {
    final database = await cosmosDB.databases.openOrCreate(getTempName(),
        throughput: CosmosDbThroughput.autoScale(50000));
    expect(database, isNotNull);
    expect(database.exists, isTrue);
    await cosmosDB.databases.delete(database);
  });

  test('Open database with openOrCreate()', () async {
    final database = await cosmosDB.databases.openOrCreate(dbName);
    expect(database, isNotNull);
    expect(database.exists, isTrue);
  });

  test('Create duplicate database fails', () async {
    await expectLater(
      cosmosDB.databases.create(dbName),
      throwsA(isA<ConflictException>()),
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
