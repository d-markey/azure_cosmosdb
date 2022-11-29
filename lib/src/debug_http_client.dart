import 'dart:developer';

import 'package:azure_cosmosdb/src/impl/_http_status_codes.dart';
import 'package:http/http.dart' as http;

import 'impl/_debug_http_overrides_web.dart'
    if (dart.library.io) 'impl/_debug_http_overrides_vm.dart';

/// Debug HTTP client that can be used to trace request/responses. This client also
/// installs a global HTTP override object to accept self-signed certificates.
/// DO NOT USE IN PRODUCTION.
class DebugHttpClient extends http.BaseClient {
  DebugHttpClient({this.trace = false}) {
    allowSelfSignedCertificates();
  }

  /// Enable/disable request/response tracing.
  bool trace;

  /// Enable/disable headers tracing.
  bool traceHeaders = false;

  /// Enable/disable forced forbidden (status code 403) response.
  bool forceForbidden = false;

  final _http = http.Client();

  @override
  void close() => _http.close();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    String? ts;
    if (trace) {
      ts = DateTime.now().toUtc().toIso8601String();
      log('>>>>>>>>>>>>>>>>');
      log('[$ts] --> ${request.method} ${request.url}');
      if (traceHeaders) {
        for (var h in request.headers.entries) {
          print('[$ts] --> ${h.key} = ${h.value}');
        }
      }
    }
    http.StreamedResponse response;
    if (forceForbidden) {
      response = http.StreamedResponse(
        Stream<List<int>>.fromIterable([]),
        HttpStatusCode.forbidden,
        reasonPhrase: 'Forced',
      );
    } else {
      response = await _http.send(request);
    }
    if (trace) {
      log('[$ts] <-- status code ${response.statusCode} ${response.reasonPhrase}');
      if (traceHeaders) {
        for (var h in response.headers.entries) {
          log('[$ts] <-- ${h.key} = ${h.value}');
        }
      }
      log('<<<<<<<<<<<<<<<<');
    }
    return response;
  }
}
