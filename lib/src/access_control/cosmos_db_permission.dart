import 'package:http/http.dart' as http;

import '../../azure_cosmosdb.dart';
import '../_internal/_http_header.dart';

/// Class representing a CosmosDB permission.
class CosmosDbPermission extends BaseDocument
    with EtagMixin
    implements CosmosDbAccessControl {
  CosmosDbPermission(this.id, this.mode, this.resource, [this.token]);

  CosmosDbPermission.fromToken(String token)
      : this('', PermissionMode.opaque, '', token);

  @override
  final String id;

  /// The permission's mode (see [PermissionMode]).
  final PermissionMode mode;

  /// The resource covered by this permission.
  final String resource;

  /// The permission's token generated by CosmosDB.
  final String? token;

  @override
  JSonMessage toJson() => {
        'id': id,
        'permissionMode': mode.name,
        'resource': resource,
      };

  /// Builds a [CosmosDbPermission] from a CosmosDB JSON object.
  static CosmosDbPermission build(Map json) {
    final permission = CosmosDbPermission(
        json['id'],
        PermissionMode.parse(json['permissionMode']),
        json['resource'],
        json['_token']);
    permission.setEtag(json);
    return permission;
  }

  @override
  void authorize(http.Request request) {
    if (token == null) {
      throw CosmosDbException(
        HttpStatusCode.invalidToken,
        'Permission has no token',
      );
    }
    request.headers[HttpHeader.authorization] = Uri.encodeComponent(token!);
  }
}
