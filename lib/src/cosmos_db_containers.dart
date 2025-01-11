import 'authorizations/cosmos_db_authorization.dart';
import 'authorizations/cosmos_db_permission.dart';
import 'client/_context.dart';
import 'cosmos_db_container.dart';
import 'cosmos_db_database.dart';
import 'cosmos_db_exceptions.dart';
import 'cosmos_db_throughput.dart';
import 'indexing/geospatial_config.dart';
import 'indexing/indexing_policy.dart';
import 'partition/partition_key_spec.dart';

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
  Future<Iterable<CosmosDbContainer>> list(
          {CosmosDbPermission? permission,
          CosmosDbAuthorization? authorization}) =>
      database.client.getMany<CosmosDbContainer>(
        url,
        'DocumentCollections',
        Context(
          type: 'colls',
          resId: database.url,
          builder: fromJson,
          authorization: CosmosDbAuthorization.from(authorization, permission),
        ),
      );

  /// Deletes the specified [container] from this [database]. All documents in this
  /// [container] will be lost. If the [container] does not exists, this method
  /// returns `true` by default. if [throwOnNotFound] is set to `true`, it will throw
  /// a [NotFoundException] instead. Upon success, the [CosmosDbContainer.exists] flag will
  /// be set to `false`.
  Future<bool> delete(CosmosDbContainer container,
          {bool throwOnNotFound = false,
          CosmosDbPermission? permission,
          CosmosDbAuthorization? authorization}) =>
      database.client
          .delete(
        '$url/${container.id}',
        Context(
          type: 'colls',
          throwOnNotFound: throwOnNotFound,
          authorization: CosmosDbAuthorization.from(authorization, permission),
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
    CosmosDbAuthorization? authorization,
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
          authorization: CosmosDbAuthorization.from(authorization, permission),
          builder: fromJson,
        ),
      );

  /// Opens an existing [CosmosDbContainer] with id [name].
  Future<CosmosDbContainer> open(
    String name, {
    CosmosDbPermission? permission,
    CosmosDbAuthorization? authorization,
  }) =>
      CosmosDbContainer(database, name).getInfo(
        permission: permission,
        authorization: authorization,
      );

  /// Opens or creates a [CosmosDbContainer] with id [name].
  Future<CosmosDbContainer> openOrCreate(
    String name, {
    PartitionKeySpec? partitionKey,
    IndexingPolicy? indexingPolicy,
    GeospatialConfig? geospatialConfig,
    CosmosDbThroughput? throughput,
    CosmosDbPermission? permission,
    CosmosDbAuthorization? authorization,
  }) async {
    try {
      return await open(
        name,
        permission: permission,
        authorization: authorization,
      );
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
        permission: permission,
        authorization: authorization,
      );
    }
  }
}
