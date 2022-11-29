import 'impl/_context.dart';

import 'permission.dart';
import 'user.dart';
import 'users.dart';

/// Class used to manage [Permission]s for CosmosDB [Users].
class Permissions {
  Permissions(this._users);

  final Users _users;

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

  /// Lists permissions for a [user].
  Future<Iterable<Permission>> list(User user, {Permission? permission}) =>
      _users.client.getMany<Permission>(
        '${_users.url}/${user.id}/permissions',
        'Permissions',
        Context(
          type: 'permissions',
          resId: '${_users.url}/${user.id}',
          builder: Permission.build,
          token: permission?.token ?? _token,
        ),
      );

  /// Retrieves permission with id [name] for the specified [user].
  Future<Permission?> get(
    User user,
    String name, {
    Duration? expiry,
    Permission? permission,
  }) {
    final context = Context(
      type: 'permissions',
      throwOnNotFound: true,
      builder: Permission.build,
      token: permission?.token ?? _token,
    );
    final seconds = expiry?.inSeconds ?? 0;
    if (seconds > 0) {
      context.addHeader('x-ms-documentdb-expiry-seconds', seconds.toString());
    }
    return _users.client.get<Permission>(
      '${_users.url}/${user.id}/permissions/$name',
      context,
    );
  }

  /// Grants the [user] the specified [userPermission].
  Future<Permission> grant(
    User user,
    Permission userPermission, {
    Duration? expiry,
    Permission? permission,
  }) {
    final context = Context(
      type: 'permissions',
      resId: '${_users.url}/${user.id}',
      builder: Permission.build,
      token: permission?.token ?? _token,
    );
    final seconds = expiry?.inSeconds ?? 0;
    if (seconds > 0) {
      context.addHeader('x-ms-documentdb-expiry-seconds', seconds.toString());
    }
    return _users.client.post<Permission>(
      '${_users.url}/${user.id}/permissions',
      userPermission,
      context,
    );
  }

  /// Updates the [userPermission] for the specified [user].
  Future<Permission> replace(
    User user,
    Permission userPermission, {
    Duration? expiry,
    Permission? permission,
  }) {
    final context = Context(
      type: 'permissions',
      builder: Permission.build,
      token: permission?.token ?? _token,
    );
    final seconds = expiry?.inSeconds ?? 0;
    if (seconds > 0) {
      context.addHeader('x-ms-documentdb-expiry-seconds', seconds.toString());
    }
    return _users.client.put<Permission>(
      '${_users.url}/${user.id}/permissions/${userPermission.id}',
      userPermission,
      context,
    );
  }

  /// Revokes permission with `id` for the specified [user].
  Future<bool> revoke(User user, String name,
          {bool throwOnNotFound = false, Permission? permission}) =>
      _users.client.delete(
        '${_users.url}/${user.id}/permissions/$name',
        Context(
          type: 'permissions',
          throwOnNotFound: throwOnNotFound,
          builder: Permission.build,
          token: permission?.token ?? _token,
        ),
      );
}
