import '_context.dart';

import 'database.dart';
import 'permissions.dart';
import 'user.dart';

class Users {
  Users(Database db)
      : database = db,
        url = '${db.url}/users';

  final Database database;
  final String url;

  late final Permissions permissions = Permissions(this);

  Future<bool> delete(String id, {bool throwOnNotFound = false}) =>
      database.client.delete(
        '$url/$id',
        Context(
          type: 'users',
          throwOnNotFound: throwOnNotFound,
        ),
      );

  Future<User?> find(String id, {bool throwOnNotFound = false}) =>
      database.client.get<User>(
        '$url/$id',
        Context(
          type: 'users',
          throwOnNotFound: throwOnNotFound,
        ),
      );

  Future<User> add(User user) => database.client.post<User>(
        url,
        user,
        Context(
          resId: database.url,
          type: 'users',
        ),
      );
}
