import 'impl/_client.dart';
import 'impl/_context.dart';

import 'base_document.dart';
import 'collections.dart';
import 'permission.dart';
import 'server.dart';
import 'users.dart';

/// Class representing a CosmosDB database.
class Database extends BaseDocument {
  Database(this.server, this.id) : url = 'dbs/$id';

  /// The [server] hosting this database.
  final Instance server;

  /// The database's base [url].
  final String url;

  /// Flag indicating whether the database exists in CosmosDB.
  /// `null` if no check has been made yet.
  bool? get exists => _exists;
  bool? _exists;

  @override
  final String id;

  @override
  Map<String, dynamic> toJson() => {'id': id};

  void registerBuilder<T extends BaseDocument>(DocumentBuilder<T> builder) =>
      client.registerBuilder<T>(builder);

  /// Gets information for this [Database].
  Future<Map<String, dynamic>?> getInfo({Permission? permission}) =>
      client.getJson(
          url,
          Context(
            type: 'dbs',
            token: permission?.token,
          ));

  /// Provides access to collections in this [Database].
  late final Collections collections = Collections(this);

  /// Provides access to users in this [Database].
  late final Users users = Users(this);
}

// internal use
extension DatabaseExt on Database {
  void setExists(bool exists) => _exists = exists;

  Client get client => server.client;
}
