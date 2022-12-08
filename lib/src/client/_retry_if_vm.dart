import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'debug_http_client.dart';

bool retryIf(http.Client client, Exception e) {
  if (client is DebugHttpClient) {
    log('!!! received exception $e');
  }
  final retry = e is SocketException ||
      e is TimeoutException ||
      e is http.ClientException;
  if (retry) {
    log('retrying on error ${e.runtimeType}...');
  }
  return retry;
}
