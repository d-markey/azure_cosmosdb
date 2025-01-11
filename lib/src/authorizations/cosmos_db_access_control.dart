import 'cosmos_db_authorization.dart';
import 'cosmos_db_permission.dart';

/// Abstraction for access-control management. Used as a marker to identify
/// classes related to security aspects. It is implemented by
/// [CosmosDbAuthorization] and [CosmosDbPermission].
abstract class CosmosDbAccessControl {}
