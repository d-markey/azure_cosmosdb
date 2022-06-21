import '_context.dart';

import 'collection.dart';
import 'database.dart';
import 'exceptions.dart';
import 'permission.dart';

/// Class used to manage [Collection]s in a [Database].
class Collections {
  Collections(this.database) : _url = '${database.url}/colls';

  /// The owner [Database].
  final Database database;

  final String _url;

  Collection _build(Map json) {
    final coll = Collection(database, json['id']);
    coll.setExists(true);
    return coll;
  }

  /// Lists all collections from this [database].
  Future<Iterable<Collection>> list({Permission? permission}) =>
      database.client.getMany<Collection>(
        _url,
        'DocumentCollections',
        Context(
          type: 'colls',
          resId: database.url,
          builder: _build,
          token: permission?.token,
        ),
      );

  /// Deletes the specified [collection] from this [database]. All documents in this
  /// [collection] will be lost. If the [collection] does not exists, this method
  /// returns `true` by default. if [throwOnNotFound] is set to `true`, it will throw
  /// a [NotFoundException] instead. Upon success, the [Collection.exists] flag will
  /// be set to `false`.
  Future<bool> delete(Collection collection,
          {bool throwOnNotFound = false, Permission? permission}) =>
      database.client
          .delete(
        '$_url/${collection.id}',
        Context(
          type: 'colls',
          throwOnNotFound: throwOnNotFound,
          token: permission?.token,
        ),
      )
          .then((value) {
        collection.setExists(false);
        return true;
      });

  /// Creates a new [Collection] with the specified `name` and `partitionKeys`.
  Future<Collection> create(String name,
          {List<String>? partitionKeys, Permission? permission}) =>
      database.client.post<Collection>(
        _url,
        Collection(database, name, partitionKeys: partitionKeys),
        Context(
          type: 'colls',
          resId: database.url,
          headers: {
            'x-ms-offer-throughput': '400',
          },
          builder: _build,
        ),
      );

  /// Opens an existing [Collection] with id [name].
  Future<Collection> open(String name) async {
    final coll = Collection(database, name);
    await coll.getInfo();
    coll.setExists(true);
    return coll;
  }

  /// Opens or creates a [Collection] with id [name].
  Future<Collection> openOrCreate(String name,
      {List<String>? partitionKeys}) async {
    try {
      return await open(name);
    } on NotFoundException {
      return await create(name, partitionKeys: partitionKeys);
    }
  }
}
