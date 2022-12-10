import 'package:http/http.dart' as http;

import '_authorization.dart';
import '_http_header.dart';
import '_http_methods.dart';

class HttpCall {
  const HttpCall(this.method, this.uri);

  const HttpCall.get(this.uri) : method = HttpMethod.get;
  const HttpCall.post(this.uri) : method = HttpMethod.post;
  const HttpCall.put(this.uri) : method = HttpMethod.put;
  const HttpCall.patch(this.uri) : method = HttpMethod.patch;
  const HttpCall.delete(this.uri) : method = HttpMethod.delete;

  final HttpMethod method;
  final String uri;

  http.Request getRequest(String root, Authorization authorization) {
    final request = http.Request(method.name, Uri.parse(root + uri));
    request.headers[HttpHeader.authorization] = authorization.token;
    request.headers[HttpHeader.msDate] = authorization.date;
    request.headers.addAll(HttpHeader.apiVersion);
    return request;
  }
}
