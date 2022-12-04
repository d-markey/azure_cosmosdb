import '../client/_context.dart';
import 'cosmos_db_permission.dart';
import 'cosmos_db_user.dart';
import 'cosmos_db_users.dart';

@Deprecated('Use CosmosDbPermissions instead.')
typedef Permissions = CosmosDbPermissions;

/// Class used to manage [CosmosDbPermission]s for CosmosDB [CosmosDbUsers].
class CosmosDbPermissions {
  CosmosDbPermissions(this._users);

  final CosmosDbUsers _users;

  /// Lists permissions for a [user].
  Future<Iterable<CosmosDbPermission>> list(CosmosDbUser user,
          {CosmosDbPermission? permission}) =>
      _users.client.getMany<CosmosDbPermission>(
        '${_users.url}/${user.id}/permissions',
        'Permissions',
        Context(
          type: 'permissions',
          resId: '${_users.url}/${user.id}',
          builder: CosmosDbPermission.build,
          token: permission?.token,
        ),
      );

  /// Retrieves permission with id [name] for the specified [user].
  Future<CosmosDbPermission?> get(
    CosmosDbUser user,
    String name, {
    Duration? expiry,
    CosmosDbPermission? permission,
  }) {
    final context = Context(
      type: 'permissions',
      throwOnNotFound: true,
      builder: CosmosDbPermission.build,
      token: permission?.token,
    );
    final seconds = expiry?.inSeconds ?? 0;
    if (seconds > 0) {
      context.addHeader('x-ms-documentdb-expiry-seconds', seconds.toString());
    }
    return _users.client.get<CosmosDbPermission>(
      '${_users.url}/${user.id}/permissions/$name',
      context,
    );
  }

  /// Grants the [user] the specified [userPermission].
  Future<CosmosDbPermission> grant(
    CosmosDbUser user,
    CosmosDbPermission userPermission, {
    Duration? expiry,
    CosmosDbPermission? permission,
  }) {
    final context = Context(
      type: 'permissions',
      resId: '${_users.url}/${user.id}',
      builder: CosmosDbPermission.build,
      token: permission?.token,
    );
    final seconds = expiry?.inSeconds ?? 0;
    if (seconds > 0) {
      context.addHeader('x-ms-documentdb-expiry-seconds', seconds.toString());
    }
    return _users.client.post<CosmosDbPermission>(
      '${_users.url}/${user.id}/permissions',
      userPermission,
      context,
    );
  }

  /// Updates the [userPermission] for the specified [user].
  Future<CosmosDbPermission> replace(
    CosmosDbUser user,
    CosmosDbPermission userPermission, {
    Duration? expiry,
    CosmosDbPermission? permission,
  }) {
    final context = Context(
      type: 'permissions',
      builder: CosmosDbPermission.build,
      token: permission?.token,
    );
    final seconds = expiry?.inSeconds ?? 0;
    if (seconds > 0) {
      context.addHeader('x-ms-documentdb-expiry-seconds', seconds.toString());
    }
    return _users.client.put<CosmosDbPermission>(
      '${_users.url}/${user.id}/permissions/${userPermission.id}',
      userPermission,
      context,
    );
  }

  /// Revokes permission with `id` for the specified [user].
  Future<bool> revoke(CosmosDbUser user, String name,
          {bool throwOnNotFound = false, CosmosDbPermission? permission}) =>
      _users.client.delete(
        '${_users.url}/${user.id}/permissions/$name',
        Context(
          type: 'permissions',
          throwOnNotFound: throwOnNotFound,
          builder: CosmosDbPermission.build,
          token: permission?.token,
        ),
      );
}
