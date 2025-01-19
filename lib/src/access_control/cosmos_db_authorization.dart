import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;

import '../_internal/_http_header.dart';
import '../_internal/_imf_fixdate.dart';
import '../client/http_status_codes.dart';
import '../cosmos_db_exceptions.dart';
import 'cosmos_db_access_control.dart';

/// Class representing a CosmosDB authorization. This class holds both the
/// [token] and the [msDate] which are used to populate the HTTP headers when
/// sending a request to Azure CosmosDB:
/// * [token] is sent via the `authorization` header,
/// * [msDate] is sent via the `x-ms-date` header.
class CosmosDbAuthorization implements CosmosDbAccessControl {
  /// Directly build a CosmosDB authorization using the supplied [token] and
  /// [msDate]. The provided [token] will be stored after URI-encoding.
  CosmosDbAuthorization(this.token, {this.msDate});

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
    final date = _msDate(DateTime.now());
    final payload = '$method\n$type\n$resId\n$date\n\n';
    final signature = base64Encode(key.convert(utf8.encode(payload)).bytes);
    return CosmosDbAuthorization(
      'type=master&ver=1.0&sig=$signature',
      msDate: date,
    );
  }

  final String? msDate;
  final String token;

  @override
  void authorize(http.Request request) {
    request.headers[HttpHeader.authorization] = Uri.encodeComponent(token);
    if (msDate != null) {
      request.headers[HttpHeader.msDate] = msDate!;
    }
  }

  static String _msDate(DateTime date) => date.toImfFixedString().toLowerCase();
}
