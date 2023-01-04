import 'base_document.dart';
import 'client/_client.dart';
import 'client/_context.dart';
import 'cosmos_db_collections.dart';
import 'permissions/cosmos_db_permission.dart';
import 'permissions/cosmos_db_users.dart';
import 'cosmos_db_server.dart';

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

  void registerBuilder<T extends BaseDocument>(DocumentBuilder<T> builder) =>
      client.registerBuilder<T>(builder);

  /// Gets information for this [CosmosDbDatabase].
  Future<dynamic> getInfo({CosmosDbPermission? permission}) => client.rawGet(
      url,
      Context(
        type: 'dbs',
        token: permission?.token,
      ));

  /// Provides access to collections in this [CosmosDbDatabase].
  late final CosmosDbCollections collections = CosmosDbCollections(this);

  /// Provides access to users in this [CosmosDbDatabase].
  late final CosmosDbUsers users = CosmosDbUsers(this);
}

// internal use
extension DatabaseExt on CosmosDbDatabase {
  void setExists(bool exists) => _exists = exists;

  Client get client => server.client;
}
