import '../client/_client.dart';
import '../client/_context.dart';
import '../cosmos_db_database.dart';
import '../cosmos_db_exceptions.dart';
import 'cosmos_db_permission.dart';
import 'cosmos_db_permissions.dart';
import 'cosmos_db_user.dart';

/// Class used to manage [CosmosDbUser]s in a CosmosDB [CosmosDbDatabase].
class CosmosDbUsers {
  CosmosDbUsers(CosmosDbDatabase db)
      : database = db,
        url = '${db.url}/users';

  final CosmosDbDatabase database;
  final String url;

  /// Provides access to permissions associated with [CosmosDbUser]s.
  late final CosmosDbPermissions permissions = CosmosDbPermissions(this);

  /// Lists all collections from this [database].
  Future<Iterable<CosmosDbUser>> list({CosmosDbPermission? permission}) =>
      database.client.getMany<CosmosDbUser>(
        url,
        'Users',
        Context(
          type: 'users',
          resId: database.url,
          builder: CosmosDbUser.build,
          token: permission?.token,
        ),
      );

  /// Deletes the user identified by [id]. By default, this method returns `true` if
  /// the user does not exists. If [throwOnNotFound] is set to `true`, it will throw a
  /// [NotFoundException] instead.
  Future<bool> delete(String id,
          {bool throwOnNotFound = false, CosmosDbPermission? permission}) =>
      database.client.delete(
        '$url/$id',
        Context(
          type: 'users',
          throwOnNotFound: throwOnNotFound,
          builder: CosmosDbUser.build,
          token: permission?.token,
        ),
      );

  /// Finds the user identified by [id]. By default, this method returns `null` if
  /// the user does not exists. If [throwOnNotFound] is set to `true`, it will throw a
  /// [NotFoundException] instead.
  Future<CosmosDbUser?> find(String id,
          {bool throwOnNotFound = false, CosmosDbPermission? permission}) =>
      database.client.get<CosmosDbUser>(
        '$url/$id',
        Context(
          type: 'users',
          throwOnNotFound: throwOnNotFound,
          builder: CosmosDbUser.build,
          token: permission?.token,
        ),
      );

  /// Adds [user] to the [database] the user identified by [id]. By default, this method returns `null` if
  /// the user does not exists. If [throwOnNotFound] is set to `true`, it will throw a
  /// [NotFoundException] instead.
  Future<CosmosDbUser> add(CosmosDbUser user,
          {CosmosDbPermission? permission}) =>
      database.client.post<CosmosDbUser>(
        url,
        user,
        Context(
          resId: database.url,
          type: 'users',
          builder: CosmosDbUser.build,
          token: permission?.token,
        ),
      );
}

// internal use
extension CosmosDbUsersExt on CosmosDbUsers {
  Client get client => database.client;
}
