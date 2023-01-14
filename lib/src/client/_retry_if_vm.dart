import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'debug_http_client.dart';

bool retryIf(http.Client client, Exception e) {
  final retry = e is SocketException ||
      e is TimeoutException ||
      e is http.ClientException;
  if (client is DebugHttpClient && client.trace) {
    final action = retry ? 'retrying' : 'ignoring';
    print('!!! received exception ${e.runtimeType}: $action');
  }
  return retry;
}
