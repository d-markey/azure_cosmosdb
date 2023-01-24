import 'package:meta/meta.dart';

import 'base_document.dart';
import 'client/_client.dart';
import 'client/_context.dart';
import 'cosmos_db_containers.dart';
import 'cosmos_db_server.dart';
import 'permissions/cosmos_db_permission.dart';
import 'permissions/cosmos_db_users.dart';

/// Class representing a CosmosDB database.
class CosmosDbDatabase extends BaseDocument {
  CosmosDbDatabase(this.server, this.id) : url = 'dbs/$id';

  /// The [server] hosting this database.
  final CosmosDbServer server;

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

  /// Gets information for this [CosmosDbDatabase].
  Future<dynamic> getInfo({CosmosDbPermission? permission}) => client.rawGet(
      url,
      Context(
        type: 'dbs',
        token: permission?.token,
      ));

  /// Provides access to containers in this [CosmosDbDatabase].
  late final CosmosDbContainers containers = CosmosDbContainers(this);

  /// Provides access to users in this [CosmosDbDatabase].
  late final CosmosDbUsers users = CosmosDbUsers(this);
}

// internal use
@internal
extension CosmosDbDatabaseInternalExt on CosmosDbDatabase {
  void setExists(bool exists) => _exists = exists;

  Client get client => server.client;
}
