import '_client.dart';
import '_context.dart';

import 'database.dart';
import 'exceptions.dart';
import 'permission.dart';
import 'permissions.dart';
import 'user.dart';

/// Class used to manage [User]s in a CosmosDB [Database].
class Users {
  Users(Database db)
      : database = db,
        url = '${db.url}/users';

  final Database database;
  final String url;

  /// Provides access to permissions associated with [User]s.
  late final Permissions permissions = Permissions(this);

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

  /// Deletes the user identified by [id]. By default, this method returns `true` if
  /// the user does not exists. If [throwOnNotFound] is set to `true`, it will throw a
  /// [NotFoundException] instead.
  Future<bool> delete(String id,
          {bool throwOnNotFound = false, Permission? permission}) =>
      database.client.delete(
        '$url/$id',
        Context(
          type: 'users',
          throwOnNotFound: throwOnNotFound,
          builder: User.build,
          token: permission?.token ?? _token,
        ),
      );

  /// Finds the user identified by [id]. By default, this method returns `null` if
  /// the user does not exists. If [throwOnNotFound] is set to `true`, it will throw a
  /// [NotFoundException] instead.
  Future<User?> find(String id,
          {bool throwOnNotFound = false, Permission? permission}) =>
      database.client.get<User>(
        '$url/$id',
        Context(
          type: 'users',
          throwOnNotFound: throwOnNotFound,
          builder: User.build,
          token: permission?.token ?? _token,
        ),
      );

  /// Adds [user] to the [database] the user identified by [id]. By default, this method returns `null` if
  /// the user does not exists. If [throwOnNotFound] is set to `true`, it will throw a
  /// [NotFoundException] instead.
  Future<User> add(User user, {Permission? permission}) =>
      database.client.post<User>(
        url,
        user,
        Context(
          resId: database.url,
          type: 'users',
          builder: User.build,
          token: permission?.token ?? _token,
        ),
      );
}

// internal use
extension UsersExt on Users {
  Client get client => database.client;
}
