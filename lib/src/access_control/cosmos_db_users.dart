import 'package:meta/meta.dart';

import '../_internal/_extensions.dart';
import '../client/_client.dart';
import '../client/_context.dart';
import '../cosmos_db_database.dart';
import 'cosmos_db_access_control.dart';
import 'cosmos_db_permissions.dart';
import 'cosmos_db_user.dart';

/// Class used to manage [CosmosDbUser]s in a CosmosDB [CosmosDbDatabase].
class CosmosDbUsers {
  CosmosDbUsers(CosmosDbDatabase db)
      : database = db,
        url = buildUrl(db.url, 'users');

  final CosmosDbDatabase database;
  final String url;

  /// Provides access to permissions associated with [CosmosDbUser]s.
  late final CosmosDbPermissions permissions = CosmosDbPermissions(this);

  /// Lists all containers from this [database].
  Future<Iterable<CosmosDbUser>> list({CosmosDbAccessControl? accessControl}) =>
      database.client.getMany<CosmosDbUser>(
        url,
        'Users',
        Context(
          type: 'users',
          resId: database.url,
          builder: CosmosDbUser.build,
          accessControl: accessControl,
        ),
      );

  /// Deletes the user identified by [id]. By default, this method returns `true` if
  /// the user does not exists. If [throwOnNotFound] is set to `true`, it will throw a
  /// [NotFoundException] instead.
  Future<bool> delete(String id,
          {bool throwOnNotFound = false,
          CosmosDbAccessControl? accessControl}) =>
      database.client.delete(
        buildUrl(url, id),
        Context(
          type: 'users',
          throwOnNotFound: throwOnNotFound,
          builder: CosmosDbUser.build,
          accessControl: accessControl,
        ),
      );

  /// Finds the user identified by [id]. By default, this method returns `null` if
  /// the user does not exists. If [throwOnNotFound] is set to `true`, it will throw a
  /// [NotFoundException] instead.
  Future<CosmosDbUser?> find(String id,
          {bool throwOnNotFound = false,
          CosmosDbAccessControl? accessControl}) =>
      database.client.get<CosmosDbUser>(
        buildUrl(url, id),
        Context(
          type: 'users',
          throwOnNotFound: throwOnNotFound,
          builder: CosmosDbUser.build,
          accessControl: accessControl,
        ),
      );

  /// Adds [user] to the [database] the user identified by [id]. By default, this method returns
  /// `null` if the user does not exists. If [throwOnNotFound] is set to `true`, it will throw a
  /// [NotFoundException] instead.
  Future<CosmosDbUser> add(CosmosDbUser user,
          {CosmosDbAccessControl? accessControl}) =>
      database.client.post<CosmosDbUser>(
        url,
        user,
        Context(
          resId: database.url,
          type: 'users',
          builder: CosmosDbUser.build,
          accessControl: accessControl,
        ),
      );
}

// internal use
@internal
extension CosmosDbUsersInternalExt on CosmosDbUsers {
  Client get client => database.client;
}
