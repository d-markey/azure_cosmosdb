import 'package:http/http.dart' as http;

import '../access_control/cosmos_db_access_control.dart';
import '_http_header.dart';
import '_http_methods.dart';

class HttpCall {
  const HttpCall(this.method, this.uri, this.version);

  const HttpCall.get(String uri, String version)
      : this(HttpMethod.get, uri, version);
  const HttpCall.post(String uri, String version)
      : this(HttpMethod.post, uri, version);
  const HttpCall.put(String uri, String version)
      : this(HttpMethod.put, uri, version);
  const HttpCall.patch(String uri, String version)
      : this(HttpMethod.patch, uri, version);
  const HttpCall.delete(String uri, String version)
      : this(HttpMethod.delete, uri, version);

  final HttpMethod method;
  final String uri;

  final String version;

  http.Request getRequest(String root, CosmosDbAccessControl accessControl) {
    final request = http.Request(method.name, Uri.parse(root + uri));
    request.headers[HttpHeader.msVersion] = version;
    accessControl.authorize(request);
    return request;
  }
}
