import 'dart:convert';

import '_context.dart';

import 'collection.dart';
import 'database.dart';
import 'exceptions.dart';

class Collections {
  Collections(this.database) : url = '${database.url}/colls';

  final Database database;
  final String url;

  Collection _build(Map json) {
    final coll = Collection(database, json['id']);
    coll.setExists(true);
    return coll;
  }

  Future<Iterable<Collection>> list() => database.client.getMany<Collection>(
        url,
        'DocumentCollections',
        Context(
          type: 'colls',
          resId: database.url,
          builder: _build,
        ),
      );

  Future<bool> delete(Collection coll, {bool throwOnNotFound = false}) =>
      database.client
          .delete(
        '$url/${coll.id}',
        Context(
          type: 'colls',
          throwOnNotFound: throwOnNotFound,
        ),
      )
          .then((value) {
        coll.setExists(false);
        return true;
      });

  Future<Collection> create(String name, {List<String>? partitionKeys}) =>
      database.client.post<Collection>(
        url,
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

  Future<Collection> open(String name) async {
    final coll = Collection(database, name);
    await coll.getInfo();
    coll.setExists(true);
    return coll;
  }

  Future<Collection> openOrCreate(String name,
      {List<String>? partitionKeys}) async {
    try {
      return await open(name);
    } on NotFoundException {
      return await create(name, partitionKeys: partitionKeys);
    }
  }
}
