import 'dart:async';
import 'dart:developer';

import 'package:http/http.dart';

import 'debug_http_client.dart';

bool retryIf(Client http, Exception e) {
  if (http is DebugHttpClient) {
    log('!!! received exception $e');
  }
  final retry = e is TimeoutException || e is ClientException;
  if (retry) {
    log('retrying on error ${e.runtimeType}...');
  }
  return retry;
}
