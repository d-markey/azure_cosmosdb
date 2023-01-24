import 'dart:async';
import 'dart:developer' as dev;

import 'package:http/http.dart' as http;

import '../_internal/_http_header.dart';
import 'http_status_codes.dart';
import '_debug_http_overrides_web.dart'
    if (dart.library.io) '_debug_http_overrides_vm.dart';

/// Debug HTTP client that can be used to trace request/responses. This client also
/// installs a global HTTP override object to accept self-signed certificates.
/// DO NOT USE IN PRODUCTION.
class DebugHttpClient extends http.BaseClient {
  DebugHttpClient({this.trace = false}) {
    allowSelfSignedCertificates();
    _http = http.Client();
  }

  /// Enable/disable request/response tracing.
  bool trace;

  /// Enable/disable headers tracing.
  bool traceHeaders = false;

  /// Enable/disable body tracing.
  bool traceBody = false;

  /// Enable/disable forced forbidden (status code 403) response.
  bool forceForbidden = false;

  /// Enable/disable forced throttled delay.
  Duration? forceThrottleDelay;

  /// Enable/disable forced timeout response. When set, the next request will
  /// throw the exception and reset [forceException].
  Object? forceException;

  late final http.Client _http;

  /// Log function based on `dart:developer`'s [dev.log].
  static void defaultLog(Object? object) => dev.log(object.toString());

  /// Log function ([defaultLog] by default).
  void Function(Object? object) log = defaultLog;

  @override
  void close() => _http.close();

  Future<http.BaseRequest> _logRequest(
      String ts, http.BaseRequest request) async {
    log('>>>>>>>>>>>>>>>>');
    log('[$ts] --> ${request.method} ${request.url}');

    if (traceHeaders) {
      for (var h in request.headers.entries) {
        log('[$ts] --> ${h.key} = ${h.value}');
      }
    }

    if (traceBody) {
      if (request is http.Request) {
        log('[$ts] --> body = ${request.body}');
      } else if (request is http.StreamedRequest) {
        // get the request bytes for logging
        final bodyBytes = await request.finalize().toBytes();
        final body = String.fromCharCodes(bodyBytes);
        log('[$ts] --> body = $body');
        // rebuild the request for sending
        var req = http.Request(request.method, request.url);
        req.bodyBytes = bodyBytes;
        req.headers.addAll(request.headers);
        req.followRedirects = request.followRedirects;
        req.maxRedirects = request.maxRedirects;
        req.persistentConnection = request.persistentConnection;
        request = req;
      } else {
        log('[$ts] --> no body in $request');
      }
    }
    return request;
  }

  Future<http.StreamedResponse> _logResponse(
      String ts, http.StreamedResponse response) async {
    log('[$ts] <-- COSMOS DB Status = ${response.statusCode} ${response.reasonPhrase}');
    if (traceHeaders) {
      for (var h in response.headers.entries) {
        log('[$ts] <-- ${h.key} = ${h.value}');
      }
    }
    if (traceBody) {
      // get the response bytes for logging
      final resp = await http.Response.fromStream(response);
      log('[$ts] <-- COSMOS DB ${resp.statusCode} Payload = ${resp.body}');
      // rebuild the response
      response = http.StreamedResponse(
        Stream.fromIterable([resp.bodyBytes]),
        resp.statusCode,
        contentLength: resp.contentLength,
        headers: resp.headers,
        reasonPhrase: resp.reasonPhrase,
        isRedirect: resp.isRedirect,
        request: response.request,
      );
    }
    log('<<<<<<<<<<<<<<<<');
    return response;
  }

  Future<void> _logException(String ts, dynamic exception) async {
    log('[$ts] <-- EXCEPTION CAUGHT: $exception');
    log('<<<<<<<<<<<<<<<<');
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    String ts = DateTime.now().toUtc().toIso8601String();

    request = trace ? await _logRequest(ts, request) : request;

    http.StreamedResponse response;

    try {
      final ex = forceException;
      if (ex != null) {
        forceException = null;
        throw ex;
      }
      if (forceThrottleDelay != null) {
        final delay = forceThrottleDelay!.inMilliseconds;
        forceThrottleDelay = null;
        response = http.StreamedResponse(
          Stream<List<int>>.fromIterable([]),
          HttpStatusCode.tooManyRequests,
          reasonPhrase: 'Forced Throttle',
          headers: {HttpHeader.msRetryAfterMs: delay.toString()},
        );
      } else if (forceForbidden) {
        response = http.StreamedResponse(
          Stream<List<int>>.fromIterable([]),
          HttpStatusCode.forbidden,
          reasonPhrase: 'Forced Forbidden',
        );
      } else {
        response = await _http.send(request);
      }
      response = trace ? await _logResponse(ts, response) : response;
    } catch (ex) {
      if (trace) {
        _logException(ts, ex);
      }
      rethrow;
    }

    return response;
  }
}
