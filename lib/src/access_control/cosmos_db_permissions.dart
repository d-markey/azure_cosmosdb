import '../_internal/_extensions.dart';
import '../_internal/_http_header.dart';
import '../client/_context.dart';
import 'cosmos_db_access_control.dart';
import 'cosmos_db_permission.dart';
import 'cosmos_db_user.dart';
import 'cosmos_db_users.dart';

/// Class used to manage [CosmosDbPermission]s for CosmosDB [CosmosDbUsers].
class CosmosDbPermissions {
  CosmosDbPermissions(this._users);

  final CosmosDbUsers _users;

  /// Lists permissions for a [user].
  Future<Iterable<CosmosDbPermission>> list(CosmosDbUser user,
          {CosmosDbAccessControl? accessControl}) =>
      _users.client.getMany<CosmosDbPermission>(
        buildUrl(_users.url, user.id, 'permissions'),
        'Permissions',
        Context(
          type: 'permissions',
          resId: buildUrl(_users.url, user.id),
          builder: CosmosDbPermission.build,
          accessControl: accessControl,
        ),
      );

  /// Retrieves permission with id [name] for the specified [user].
  Future<CosmosDbPermission?> get(CosmosDbUser user, String name,
      {Duration? expiry, CosmosDbAccessControl? accessControl}) {
    final context = Context(
      type: 'permissions',
      throwOnNotFound: true,
      builder: CosmosDbPermission.build,
      accessControl: accessControl,
    );
    final seconds = expiry?.inSeconds ?? 0;
    if (seconds > 0) {
      context.addHeader(
          HttpHeader.msDocumentDbExpirySeconds, seconds.toString());
    }
    return _users.client.get<CosmosDbPermission>(
      buildUrl(_users.url, user.id, 'permissions', name),
      context,
    );
  }

  /// Grants the [user] the specified [userPermission].
  Future<CosmosDbPermission> grant(
      CosmosDbUser user, CosmosDbPermission userPermission,
      {Duration? expiry, CosmosDbAccessControl? accessControl}) {
    final context = Context(
      type: 'permissions',
      resId: buildUrl(_users.url, user.id),
      builder: CosmosDbPermission.build,
      accessControl: accessControl,
    );
    final seconds = expiry?.inSeconds ?? 0;
    if (seconds > 0) {
      context.addHeader(
          HttpHeader.msDocumentDbExpirySeconds, seconds.toString());
    }
    return _users.client.post<CosmosDbPermission>(
      buildUrl(_users.url, user.id, 'permissions'),
      userPermission,
      context,
    );
  }

  /// Updates the [userPermission] for the specified [user].
  Future<CosmosDbPermission> replace(
      CosmosDbUser user, CosmosDbPermission userPermission,
      {Duration? expiry, CosmosDbAccessControl? accessControl}) {
    final context = Context(
      type: 'permissions',
      builder: CosmosDbPermission.build,
      accessControl: accessControl,
    );
    final seconds = expiry?.inSeconds ?? 0;
    if (seconds > 0) {
      context.addHeader(
          HttpHeader.msDocumentDbExpirySeconds, seconds.toString());
    }
    return _users.client.put<CosmosDbPermission>(
      buildUrl(_users.url, user.id, 'permissions', userPermission.id),
      userPermission,
      context,
    );
  }

  /// Revokes permission with `id` for the specified [user].
  Future<bool> revoke(CosmosDbUser user, String name,
          {bool throwOnNotFound = false,
          CosmosDbAccessControl? accessControl}) =>
      _users.client.delete(
        buildUrl(_users.url, user.id, 'permissions', name),
        Context(
          type: 'permissions',
          throwOnNotFound: throwOnNotFound,
          builder: CosmosDbPermission.build,
          accessControl: accessControl,
        ),
      );
}
