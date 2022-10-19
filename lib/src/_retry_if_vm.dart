import 'dart:async';
import 'dart:io';

import 'package:http/http.dart';

import 'debug_http_client.dart';

bool retryIf(Client http, Exception e) {
  if (http is DebugHttpClient) {
    print('!!! received exception $e');
  }
  return e is SocketException || e is TimeoutException;
}
