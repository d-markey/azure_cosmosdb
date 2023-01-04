import 'client/_context.dart';
import 'cosmos_db_collection.dart';
import 'cosmos_db_database.dart';
import 'cosmos_db_exceptions.dart';
import 'cosmos_db_throughput.dart';
import 'indexing/geospatial_config.dart';
import 'indexing/indexing_policy.dart';
import 'partition/partition_key_spec.dart';
import 'permissions/cosmos_db_permission.dart';

/// Class used to manage [CosmosDbCollection]s in a [CosmosDbDatabase].
class CosmosDbCollections {
  CosmosDbCollections(this.database) : url = '${database.url}/colls';

  /// The owner [CosmosDbDatabase].
  final CosmosDbDatabase database;

  final String url;

  CosmosDbCollection fromJson(Map json) {
    final coll = CosmosDbCollection(database, json['id'],
        partitionKeySpec: PartitionKeySpec.fromJson(json['partitionKey']));
    coll.setExists(true);
    return coll;
  }

  /// Lists all collections from this [database].
  Future<Iterable<CosmosDbCollection>> list({CosmosDbPermission? permission}) =>
      database.client.getMany<CosmosDbCollection>(
        url,
        'DocumentCollections',
        Context(
          type: 'colls',
          resId: database.url,
          builder: fromJson,
          token: permission?.token,
        ),
      );

  /// Deletes the specified [collection] from this [database]. All documents in this
  /// [collection] will be lost. If the [collection] does not exists, this method
  /// returns `true` by default. if [throwOnNotFound] is set to `true`, it will throw
  /// a [NotFoundException] instead. Upon success, the [CosmosDbCollection.exists] flag will
  /// be set to `false`.
  Future<bool> delete(CosmosDbCollection collection,
          {bool throwOnNotFound = false, CosmosDbPermission? permission}) =>
      database.client
          .delete(
        '$url/${collection.id}',
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

  /// Creates a new [CosmosDbCollection] with the specified `name` and `partitionKeys`.
  Future<CosmosDbCollection> create(
    String name, {
    required PartitionKeySpec partitionKey,
    IndexingPolicy? indexingPolicy,
    GeospatialConfig? geospatialConfig,
    CosmosDbPermission? permission,
    CosmosDbThroughput? throughput,
  }) =>
      database.client.post<CosmosDbCollection>(
        url,
        CosmosDbCollection(
          database,
          name,
          partitionKeySpec: partitionKey,
          indexingPolicy: indexingPolicy,
          geospatialConfig: geospatialConfig,
        ),
        Context(
          type: 'colls',
          resId: database.url,
          headers: (throughput ?? CosmosDbThroughput.minimum).header,
          builder: fromJson,
        ),
      );

  /// Opens an existing [CosmosDbCollection] with id [name].
  Future<CosmosDbCollection> open(String name) =>
      CosmosDbCollection(database, name).getInfo();

  /// Opens or creates a [CosmosDbCollection] with id [name].
  Future<CosmosDbCollection> openOrCreate(
    String name, {
    PartitionKeySpec? partitionKey,
    IndexingPolicy? indexingPolicy,
    GeospatialConfig? geospatialConfig,
    CosmosDbThroughput? throughput,
  }) async {
    try {
      return await open(name);
    } on NotFoundException {
      return await create(
        name,
        partitionKey: partitionKey!,
        indexingPolicy: indexingPolicy,
        geospatialConfig: geospatialConfig,
        throughput: throughput,
      );
    }
  }
}
