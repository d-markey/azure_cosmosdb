import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

import '../_internal/_http_status_codes.dart';
import '../cosmos_db_exceptions.dart';
import '_imf_fixdate.dart';

class Authorization {
  Authorization.fromKey(
      crypto.Hmac? key, String method, String type, String resId) {
    if (key == null) {
      throw CosmosDbException(
        HttpStatusCode.unauthorized,
        'Missing master key',
      );
    }
    date = DateTime.now().toImfFixedString();
    final payload = '$method\n$type\n$resId\n${date.toLowerCase()}\n\n';
    final signature = base64Encode(key.convert(utf8.encode(payload)).bytes);
    token = Uri.encodeComponent('type=master&ver=1.0&sig=$signature');
  }

  Authorization.fromToken(String token) {
    date = DateTime.now().toImfFixedString();
    this.token = Uri.encodeComponent(token);
  }

  late final String date;
  late final String token;
}
