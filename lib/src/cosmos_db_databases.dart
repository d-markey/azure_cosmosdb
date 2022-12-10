import 'client/_client.dart';
import 'client/_context.dart';
import 'cosmos_db_database.dart';
import 'cosmos_db_exceptions.dart';
import 'cosmos_db_throughput.dart';
import 'permissions/cosmos_db_permission.dart';
import 'cosmos_db_server.dart';

@Deprecated('Use CosmosDbDatabases instead.')
typedef Databases = CosmosDbDatabases;

/// Class used to manage [CosmosDbDatabase]s in a [CosmosDbServer].
class CosmosDbDatabases {
  CosmosDbDatabases(this.server) : _url = 'dbs';

  /// The hosting [CosmosDbServer].
  final CosmosDbServer server;

  final String _url;

  CosmosDbDatabase _build(Map json) {
    final db = CosmosDbDatabase(server, json['id']);
    db.setExists(true);
    return db;
  }

  /// Lists all databases from this [server].
  Future<Iterable<CosmosDbDatabase>> list({CosmosDbPermission? permission}) =>
      client.getMany<CosmosDbDatabase>(
        _url,
        'Databases',
        Context(
          type: 'dbs',
          resId: '',
          builder: _build,
          token: permission?.token,
        ),
      );

  /// Deletes the specified [database] from this [server]. All collections and associated
  /// documents will be lost. If the [database] does not exists, this method returns
  /// `true` by default. if [throwOnNotFound] is set to `true`, it will throw a
  /// [NotFoundException] instead. Upon success, the [CosmosDbDatabase.exists] flag will
  /// be set to `false`.
  Future<bool> delete(CosmosDbDatabase database,
          {bool throwOnNotFound = false, CosmosDbPermission? permission}) =>
      client
          .delete(
              '$_url/${database.id}',
              Context(
                type: 'dbs',
                throwOnNotFound: throwOnNotFound,
                token: permission?.token,
              ))
          .then((value) {
        database.setExists(false);
        return true;
      });

  /// Creates a new [CosmosDbDatabase] with the specified `name`.
  Future<CosmosDbDatabase> create(
    String name, {
    CosmosDbPermission? permission,
    CosmosDbThroughput? throughput,
  }) =>
      client.post<CosmosDbDatabase>(
        _url,
        CosmosDbDatabase(server, name),
        Context(
          type: 'dbs',
          resId: '',
          headers: throughput?.header,
          builder: _build,
          token: permission?.token,
        ),
      );

  /// Opens an existing [CosmosDbDatabase] with the specified `name`.
  Future<CosmosDbDatabase> open(String name,
      {CosmosDbPermission? permission}) async {
    final db = CosmosDbDatabase(server, name);
    await db.getInfo(permission: permission);
    db.setExists(true);
    return db;
  }

  /// Opens or creates a [CosmosDbDatabase] with the specified `name`.
  Future<CosmosDbDatabase> openOrCreate(
    String name, {
    CosmosDbPermission? permission,
    CosmosDbThroughput? throughput,
  }) async {
    try {
      return await open(name, permission: permission);
    } on NotFoundException {
      return await create(name, permission: permission, throughput: throughput);
    }
  }
}

// internal use
extension DatabasesExt on CosmosDbDatabases {
  Client get client => server.client;
}
