import '_client.dart';
import '_context.dart';

import 'database.dart';
import 'exceptions.dart';

class Databases {
  Databases(this.client) : url = 'dbs';

  final Client client;
  final String url;

  Database _build(Map json) {
    final db = Database(client, json['id']);
    db.setExists(true);
    return db;
  }

  Future<Iterable<Database>> list() => client.getMany<Database>(
        url,
        'Databases',
        Context(
          type: 'dbs',
          resId: '',
          builder: _build,
        ),
      );

  Future<bool> delete(Database db, {bool throwOnNotFound = false}) => client
          .delete(
        '$url/${db.id}',
        Context(
          type: 'dbs',
          throwOnNotFound: throwOnNotFound,
        ),
      )
          .then((value) {
        db.setExists(false);
        return true;
      });

  Future<Database> create(String name) => client.post<Database>(
        url,
        Database(client, name),
        Context(
          type: 'dbs',
          resId: '',
          headers: {'x-ms-offer-throughput': '400'},
          builder: _build,
        ),
      );

  Future<Database> open(String name) async {
    final db = Database(client, name);
    await db.getInfo();
    db.setExists(true);
    return db;
  }

  Future<Database> openOrCreate(String name) async {
    try {
      return await open(name);
    } on NotFoundException {
      return await create(name);
    }
  }
}
