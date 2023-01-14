/// Azure CosmosDB SQL Rest API for Dart/Flutter.
library azure_cosmosdb;

export 'package:retry/retry.dart' show RetryOptions;

export 'src/base_document.dart' hide SpecialDocument;
export 'src/batch/batch.dart';
export 'src/batch/transactional_batch.dart';
export 'src/batch/cross_partition_batch.dart';
export 'src/batch/batch_response.dart' hide BatchResponseInternalExt;
export 'src/batch/batch_operation.dart' hide BatchOperationInternalExt;
export 'src/batch/batch_operation_create.dart';
export 'src/batch/batch_operation_delete.dart';
export 'src/batch/batch_operation_read.dart';
export 'src/batch/batch_operation_upsert.dart';
export 'src/batch/batch_operation_result.dart';
export 'src/batch/batch_operation_types.dart';
export 'src/client/features.dart';
export 'src/client/http_status_codes.dart';
export 'src/cosmos_db_container.dart' hide CosmosDbContainerInternalExt;
export 'src/cosmos_db_containers.dart';
export 'src/cosmos_db_database.dart' hide CosmosDbDatabaseInternalExt;
export 'src/cosmos_db_databases.dart' hide CosmosDbDatabasesInternalExt;
export 'src/cosmos_db_exceptions.dart' hide ContextualizedExceptionInternalExt;
export 'src/cosmos_db_throughput.dart';
export 'src/indexing/bounding_box.dart';
export 'src/indexing/data_type.dart';
export 'src/indexing/geospatial_config.dart';
export 'src/indexing/index_order.dart';
export 'src/indexing/index_path.dart';
export 'src/indexing/indexing_mode.dart';
export 'src/indexing/indexing_policy.dart';
export 'src/partition/partition_key_spec.dart';
export 'src/partition/partition_key.dart';
export 'src/partition/partition_key_range.dart';
export 'src/indexing/spatial_index_path.dart';
export 'src/patch/patch.dart';
export 'src/permissions/cosmos_db_permission.dart';
export 'src/permissions/cosmos_db_permissions.dart';
export 'src/permissions/cosmos_db_user.dart';
export 'src/permissions/cosmos_db_users.dart' hide CosmosDbUsersInternalExt;
export 'src/queries/paging.dart' hide ContinuationInternalExt;
export 'src/queries/query.dart';
export 'src/cosmos_db_server.dart'
    hide CosmosDbServerDbgExt, CosmosDbServerInternalExt;
export 'src/spatial/distance_calculator.dart';
export 'src/spatial/distance_calculator_2d.dart';
export 'src/spatial/distance_calculator_3d.dart';
export 'src/spatial/distance_calculator_haversine.dart';
export 'src/spatial/line_string.dart';
export 'src/spatial/multi_polygon.dart';
export 'src/spatial/point.dart';
export 'src/spatial/polygon.dart';
export 'src/spatial/point.dart';
export 'src/spatial/shape.dart';
