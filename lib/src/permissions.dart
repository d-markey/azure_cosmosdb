import '_context.dart';

import 'client.dart';
import 'permission.dart';
import 'user.dart';
import 'users.dart';

class Permissions {
  Permissions(Users users)
      : client = users.database.client,
        url = users.url;

  final Client client;
  final String url;

  Future<Iterable<Permission>> list(User user) => client.getMany<Permission>(
        '$url/${user.id}/permissions',
        'Permissions',
        Context(
          type: 'permissions',
          resId: '$url/${user.id}',
        ),
      );

  Future<Permission?> get(
    User user,
    String name, {
    bool throwOnNotFound = false,
    Duration? expiry,
  }) {
    final context = Context(
      type: 'permissions',
      throwOnNotFound: throwOnNotFound,
    );
    final seconds = expiry?.inSeconds ?? 0;
    if (seconds > 0) {
      context.addHeader('x-ms-documentdb-expiry-seconds', seconds.toString());
    }
    return client.get<Permission>(
      '$url/${user.id}/permissions/$name',
      context,
    );
  }

  Future<Permission> grant(
    User user,
    Permission permission, {
    Duration? expiry,
  }) {
    final context = Context(
      type: 'permissions',
      resId: '$url/${user.id}',
    );
    final seconds = expiry?.inSeconds ?? 0;
    if (seconds > 0) {
      context.addHeader('x-ms-documentdb-expiry-seconds', seconds.toString());
    }
    return client.post<Permission>(
      '$url/${user.id}/permissions',
      permission,
      context,
    );
  }

  Future<Permission> replace(
    User user,
    Permission permission, {
    Duration? expiry,
  }) {
    final context = Context(
      type: 'permissions',
    );
    final seconds = expiry?.inSeconds ?? 0;
    if (seconds > 0) {
      context.addHeader('x-ms-documentdb-expiry-seconds', seconds.toString());
    }
    return client.put<Permission>(
      '$url/${user.id}/permissions/${permission.id}',
      permission,
      context,
    );
  }

  Future<bool> revoke(User user, String name, {bool throwOnNotFound = false}) =>
      client.delete(
        '$url/${user.id}/permissions/$name',
        Context(
          type: 'permissions',
          throwOnNotFound: throwOnNotFound,
        ),
      );
}
