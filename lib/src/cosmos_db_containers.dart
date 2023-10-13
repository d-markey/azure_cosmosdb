import 'client/_context.dart';
import 'cosmos_db_container.dart';
import 'cosmos_db_database.dart';
import 'cosmos_db_exceptions.dart';
import 'cosmos_db_throughput.dart';
import 'indexing/geospatial_config.dart';
import 'indexing/indexing_policy.dart';
import 'partition/partition_key_spec.dart';
import 'permissions/cosmos_db_permission.dart';

/// Class used to manage [CosmosDbContainer]s in a [CosmosDbDatabase].
class CosmosDbContainers {
  CosmosDbContainers(this.database) : url = '${database.url}/colls';

  /// The [CosmosDbDatabase] this container belongs to.
  final CosmosDbDatabase database;

  /// The container's [url].
  final String url;

  /// Deserialize data from JSON object [json] into a new [CosmosDbContainer] instance.
  /// Handles fields `id`, `partitionKey`, `indexingPolicy`.
  CosmosDbContainer fromJson(Map json) {
    final coll = CosmosDbContainer(database, json['id'],
        partitionKeySpec: PartitionKeySpec.fromJson(json['partitionKey']),
        indexingPolicy: IndexingPolicy.fromJson(json['indexingPolicy']));
    coll.setExists(true);
    return coll;
  }

  /// Lists all containers from this [database].
  Future<Iterable<CosmosDbContainer>> list({CosmosDbPermission? permission}) =>
      database.client.getMany<CosmosDbContainer>(
        url,
        'DocumentCollections',
        Context(
          type: 'colls',
          resId: database.url,
          builder: fromJson,
          token: permission?.token,
        ),
      );

  /// Deletes the specified [container] from this [database]. All documents in this
  /// [container] will be lost. If the [container] does not exists, this method
  /// returns `true` by default. if [throwOnNotFound] is set to `true`, it will throw
  /// a [NotFoundException] instead. Upon success, the [CosmosDbContainer.exists] flag will
  /// be set to `false`.
  Future<bool> delete(CosmosDbContainer container,
          {bool throwOnNotFound = false, CosmosDbPermission? permission}) =>
      database.client
          .delete(
        '$url/${container.id}',
        Context(
          type: 'colls',
          throwOnNotFound: throwOnNotFound,
          token: permission?.token,
        ),
      )
          .then((value) {
        container.setExists(false);
        return true;
      });

  /// Creates a new [CosmosDbContainer] with the specified `name` and `partitionKeys`.
  Future<CosmosDbContainer> create(
    String name, {
    required PartitionKeySpec partitionKey,
    IndexingPolicy? indexingPolicy,
    GeospatialConfig? geospatialConfig,
    CosmosDbPermission? permission,
    CosmosDbThroughput? throughput,
  }) =>
      database.client.post<CosmosDbContainer>(
        url,
        CosmosDbContainer(
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

  /// Opens an existing [CosmosDbContainer] with id [name].
  Future<CosmosDbContainer> open(String name) =>
      CosmosDbContainer(database, name).getInfo();

  /// Opens or creates a [CosmosDbContainer] with id [name].
  Future<CosmosDbContainer> openOrCreate(
    String name, {
    PartitionKeySpec? partitionKey,
    IndexingPolicy? indexingPolicy,
    GeospatialConfig? geospatialConfig,
    CosmosDbThroughput? throughput,
  }) async {
    try {
      return await open(name);
    } on NotFoundException {
      if (partitionKey == null) {
        throw ApplicationException(
            'Container \'$name\' not found - can not create with a null partion key');
      }
      return await create(
        name,
        partitionKey: partitionKey,
        indexingPolicy: indexingPolicy,
        geospatialConfig: geospatialConfig,
        throughput: throughput,
      );
    }
  }
}
