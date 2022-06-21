import 'package:http/http.dart' as http;

import '_debug_http_overrides_web.dart'
    if (dart.library.io) '_debug_http_overrides_vm.dart';

/// Debug HTTP client that can be used to trace request/responses. This client also
/// installs a global HTTP override object to accept self-signed certificates.
/// DO NOT USE IN PRODUCTION.
class DebugHttpClient extends http.BaseClient {
  DebugHttpClient({this.trace = false}) {
    allowSelfSignedCertificates();
  }

  /// Enable/disable request/response tracing.
  bool trace;

  final _http = http.Client();

  @override
  void close() => _http.close();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    String? ts;
    if (trace) {
      ts = DateTime.now().toUtc().toIso8601String();
      print('>>>>>>>>>>>>>>>>');
      print('[$ts] --> ${request.method} ${request.url}');
      for (var h in request.headers.entries) {
        print('[$ts] --> ${h.key} = ${h.value}');
      }
    }
    final response = await _http.send(request);
    if (trace) {
      print('[$ts] <-- status code ${response.statusCode}');
      for (var h in response.headers.entries) {
        print('[$ts] <-- ${h.key} = ${h.value}');
      }
      print('<<<<<<<<<<<<<<<<');
    }
    return response;
  }
}
