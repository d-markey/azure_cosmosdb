import 'package:http/http.dart' as http;

import 'cosmos_db_authorization.dart';
import 'cosmos_db_permission.dart';

/// Abstraction for access-control management. It is implemented by
/// [CosmosDbAuthorization] and [CosmosDbPermission].
abstract class CosmosDbAccessControl {
  void authorize(http.Request request);
}
