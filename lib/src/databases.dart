import '_client.dart';
import '_context.dart';

import 'database.dart';
import 'exceptions.dart';
import 'permission.dart';
import 'server.dart';

/// Class used to manage [Database]s in a [Instance].
class Databases {
  Databases(this.server) : _url = 'dbs';

  /// The hosting [Instance].
  final Instance server;

  final String _url;

  Database _build(Map json) {
    final db = Database(server, json['id']);
    db.setExists(true);
    return db;
  }

  String? _token;

  /// Use this [Permission] when invoking the CosmosDB API. Using [Permission] is a way to
  /// avoid disclosing the master key in client applications; to retrieve or create a
  /// permission, you should implement some additional API to be used by your client app.
  /// This API will protect your master keys. Most methods from [Users] support an
  /// optional [permission] argument, to allow for overriding this collection-wide
  /// [permission].
  void usePermission(Permission permission) {
    _token = permission.token;
  }

  /// Lists all databases from this [server].
  Future<Iterable<Database>> list({Permission? permission}) =>
      client.getMany<Database>(
        _url,
        'Databases',
        Context(
          type: 'dbs',
          resId: '',
          builder: _build,
          token: permission?.token ?? _token,
        ),
      );

  /// Deletes the specified [database] from this [server]. All collections and associated
  /// documents will be lost. If the [database] does not exists, this method returns
  /// `true` by default. if [throwOnNotFound] is set to `true`, it will throw a
  /// [NotFoundException] instead. Upon success, the [Database.exists] flag will
  /// be set to `false`.
  Future<bool> delete(Database database,
          {bool throwOnNotFound = false, Permission? permission}) =>
      client
          .delete(
        '$_url/${database.id}',
        Context(
          type: 'dbs',
          throwOnNotFound: throwOnNotFound,
          token: permission?.token ?? _token,
        ),
      )
          .then((value) {
        database.setExists(false);
        return true;
      });

  /// Creates a new [Database] with the specified `name`.
  Future<Database> create(String name, {Permission? permission}) =>
      client.post<Database>(
        _url,
        Database(server, name),
        Context(
          type: 'dbs',
          resId: '',
          headers: {'x-ms-offer-throughput': '400'},
          builder: _build,
          token: permission?.token ?? _token,
        ),
      );

  /// Opens an existing [Database] with the specified `name`.
  Future<Database> open(String name, {Permission? permission}) async {
    final db = Database(server, name);
    await db.getInfo(permission: permission);
    db.setExists(true);
    return db;
  }

  /// Opens or creates a [Database] with the specified `name`.
  Future<Database> openOrCreate(String name, {Permission? permission}) async {
    try {
      return await open(name, permission: permission);
    } on NotFoundException {
      return await create(name, permission: permission);
    }
  }
}

// internal use
extension DatabasesExt on Databases {
  Client get client => server.client;
}
