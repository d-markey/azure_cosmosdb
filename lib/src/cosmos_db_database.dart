import 'package:meta/meta.dart';

import '_internal/_extensions.dart';
import 'access_control/cosmos_db_access_control.dart';
import 'access_control/cosmos_db_users.dart';
import 'base_document.dart';
import 'client/_client.dart';
import 'client/_context.dart';
import 'cosmos_db_containers.dart';
import 'cosmos_db_server.dart';

/// Class representing a CosmosDB database.
class CosmosDbDatabase extends BaseDocument {
  CosmosDbDatabase(this.server, this.id) : url = buildUrl('', 'dbs', id);

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
  JSonMessage toJson() => {'id': id};

  /// Gets information for this [CosmosDbDatabase].
  Future<dynamic> getInfo({CosmosDbAccessControl? accessControl}) =>
      client.rawGet(
          url,
          Context(
            type: 'dbs',
            accessControl: accessControl,
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
