import 'dart:async';

import 'package:http/http.dart' as http;

class CustomHttpClient extends http.BaseClient {
  CustomHttpClient(this._customHeaders) {
    _http = http.Client();
  }

  final Map<String, String> _customHeaders;

  late final http.Client _http;

  @override
  void close() => _http.close();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_customHeaders);
    return _http.send(request);
  }
}
