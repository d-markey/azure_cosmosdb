import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

import '../_internal/_imf_fixdate.dart';
import '../client/http_status_codes.dart';
import '../cosmos_db_exceptions.dart';
import 'cosmos_db_access_control.dart';
import 'cosmos_db_permission.dart';

/// Class representing a CosmosDB authorization. This class holds both the
/// [token] and the [date] which are used to populate the HTTP headers when
/// sending a request to Azure CosmosDB:
/// * [token] is sent via the `authorization` header,
/// * [date] is sent via the `x-ms-date` header.
class CosmosDbAuthorization implements CosmosDbAccessControl {
  /// Directly build a CosmosDB authorization using the supplied [token] and
  /// [msDate]. The provided [token] will be stored after URI-encoding.
  CosmosDbAuthorization(String token, [DateTime? msDate])
      : token = Uri.encodeComponent(token),
        date = (msDate ?? DateTime.now()).toImfFixedString();

  /// Build a CosmosDB authorization using the supplied [key] and the target
  /// resource details.
  ///
  /// For more information, refer to:
  /// https://learn.microsoft.com/en-us/rest/api/cosmos-db/access-control-on-cosmosdb-resources#authorization-header.
  factory CosmosDbAuthorization.fromKey(
      crypto.Hmac? key, String method, String type, String resId) {
    if (key == null) {
      throw CosmosDbException(
        HttpStatusCode.unauthorized,
        'Missing master key.',
      );
    }
    final date = DateTime.now();
    final payload =
        '$method\n$type\n$resId\n${date.toImfFixedString().toLowerCase()}\n\n';
    final signature = base64Encode(key.convert(utf8.encode(payload)).bytes);
    return CosmosDbAuthorization('type=master&ver=1.0&sig=$signature', date);
  }

  /// Build a CosmosDB authorization using the supplied [permission]. The
  /// permission must be obtained from CosmosDB first. If the permission token
  /// is empty or null, thi method will throw a
  ///
  /// For more information, refer to:
  /// https://learn.microsoft.com/en-us/rest/api/cosmos-db/access-control-on-cosmosdb-resources#authorization-header.
  factory CosmosDbAuthorization.fromPermission(CosmosDbPermission permission) {
    final token = permission.token;
    if (token == null || token.isEmpty) {
      throw CosmosDbException(
        HttpStatusCode.invalidToken,
        'Permission has no token',
      );
    }
    return CosmosDbAuthorization(token);
  }

  /// Build a CosmosDB authorization using the supplied [authorization] or
  /// [permission], if any. If no
  /// permission must be obtained from CosmosDB first.
  ///
  /// For more information, refer to:
  /// https://learn.microsoft.com/en-us/rest/api/cosmos-db/access-control-on-cosmosdb-resources#authorization-header.
  static CosmosDbAuthorization? from(
    CosmosDbAuthorization? authorization,
    CosmosDbPermission? permission,
  ) =>
      (authorization != null)
          ? authorization
          : ((permission != null)
              ? CosmosDbAuthorization.fromPermission(permission)
              : null);

  late final String date;
  late final String token;
}
