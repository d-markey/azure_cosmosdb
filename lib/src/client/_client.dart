import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';

import '../_internal/_authorization.dart';
import '../_internal/_http_call.dart';
import '../_internal/_http_header.dart';
import '../_internal/_http_status_codes.dart';
import '../_internal/_mime_type.dart';
import '../base_document.dart';
import '../cosmos_db_exceptions.dart';
import '../queries/paging.dart';
import '../queries/query.dart';
import '_context.dart';
import '_retry_if_web.dart' if (dart.library.io) '_retry_if_vm.dart';

typedef _DocumentBuilder = DocumentBuilder<BaseDocument>;

class Client {
  Client(
    this._url, {
    String? masterKey,
    this.multipleWriteLocations = false,
    http.Client? httpClient,
    RetryOptions? retryOptions,
  })  : _http = httpClient ?? http.Client(),
        _retry = retryOptions ?? RetryOptions() {
    if (masterKey != null) {
      _key = crypto.Hmac(crypto.sha256, base64Decode(masterKey));
    } else {
      _key = null;
    }
  }

  final String _url;
  final bool multipleWriteLocations;
  final RetryOptions _retry;

  late final crypto.Hmac? _key;
  late final http.Client _http;

  final _builders = <Type, _DocumentBuilder>{};

  http.Client get httpClient => _http;

  void registerBuilder<T extends BaseDocument>(DocumentBuilder<T> builder) {
    _builders[T] = builder;
  }

  DocumentBuilder<T> _getBuilder<T extends BaseDocument>(Context context) {
    final builder = context.builder ?? _builders[T];
    if (builder == null) throw UnknownDocumentTypeException(T);
    return (data) {
      try {
        return builder(data) as T;
      } catch (ex) {
        throw BadResponseException(ex.toString());
      }
    };
  }

  T? _build<T extends BaseDocument>(Context context, Map? item) {
    final builder = _getBuilder<T>(context);
    return (item == null || item.isEmpty) ? null : builder(item);
  }

  Iterable<T> _buildMany<T extends BaseDocument>(Context context, List? items) {
    final builder = _getBuilder<T>(context);
    return (items ?? []).map((item) => builder(item));
  }

  Future<http.StreamedResponse> _sendWithAuth(
    HttpCall call,
    BaseDocument? body,
    Context context,
    Authorization authorization,
  ) {
    final request = call.getRequest(_url, authorization);

    if (body != null) {
      request.headers.addAll(HttpHeader.jsonPayload);
      request.body = jsonEncode(body);
    }
    if (multipleWriteLocations && !call.method.isReadOnly) {
      request.headers.addAll(HttpHeader.allowTentativeWrites);
    }

    request.headers.addAll(context.getHeaders());

    return _retry.retry(
      () => _http.send(request).timeout(Duration(seconds: 5)),
      retryIf: (e) => retryIf(_http, e),
    );
  }

  Future<dynamic> _send(
    HttpCall call,
    BaseDocument? body,
    Context context,
  ) async {
    String resId = context.resId ?? call.uri;

    var auth = (context.token != null)
        ? Authorization.fromToken(context.token!)
        : Authorization.fromKey(
            _key, call.method.name.toLowerCase(), context.type, resId);

    var result = await _sendWithAuth(call, body, context, auth);

    switch (result.statusCode) {
      case HttpStatusCode.forbidden:
        // try to get a new permission from the onForbidden callback
        final permission = await context.onForbidden?.call();
        final token = permission?.token;
        if (token != null) {
          // try again with this permission
          auth = Authorization.fromToken(token);
          result = await _sendWithAuth(call, body, context, auth);
        }
        break;
      case HttpStatusCode.tooManyRequests:
        // throttling, retry after the specified delay
        final delay =
            int.tryParse(result.headers[HttpHeader.msRetryAfterMs] ?? '');
        if (delay != null) {
          await Future.delayed(Duration(milliseconds: delay));
          result = await _sendWithAuth(call, body, context, auth);
        }
        break;
    }

    final contentType = result.headers[HttpHeader.contentType];
    if (contentType != MimeType.json) {
      throw BadResponseException('Unsupported content-type: $contentType');
    }
    final response = await result.stream.bytesToString();
    dynamic data = response.isEmpty ? {} : jsonDecode(response);

    if (!HttpStatusCode.success(result.statusCode)) {
      final message = (data is Map && data.containsKey('message'))
          ? '${result.reasonPhrase}: ${data['message']}'
          : result.reasonPhrase;
      final ex = CosmosDbException(result.statusCode, message);
      if (ex is! NotFoundException || context.throwOnNotFound) {
        throw ex;
      }
      // set data to null when ignoring the error
      data = null;
    }

    context.paging?.setContinuation(
      result.headers[HttpHeader.msContinuation] ?? '',
    );
    return data;
  }

  Future<dynamic> getJson(String path, Context context) {
    final call = HttpCall.get(path);
    return _send(call, null, context).rethrowContextualizedException(call);
  }

  Future<T?> get<T extends BaseDocument>(String path, Context context) {
    final call = HttpCall.get(path);
    return _send(call, null, context)
        .then((data) => _build<T>(context, data))
        .rethrowContextualizedException(call);
  }

  Future<Iterable<T>> getMany<T extends BaseDocument>(
      String path, String resultSet, Context context) {
    final call = HttpCall.get(path);
    return _send(call, null, context)
        .then((result) => _buildMany<T>(context, result![resultSet]))
        .rethrowContextualizedException(call);
  }

  Future<T> post<T extends BaseDocument>(
      String path, BaseDocument doc, Context context) {
    final call = HttpCall.post(path);
    return _send(call, doc, context)
        .then((data) => _build<T>(context, data)!)
        .rethrowContextualizedException(call);
  }

  Future<T> patch<T extends BaseDocument>(
      String path, BaseDocument doc, Context context) {
    final call = HttpCall.patch(path);
    return _send(call, doc, context.copyWith(headers: HttpHeader.patchPayload))
        .then((data) => _build<T>(context, data)!)
        .rethrowContextualizedException(call);
  }

  Future<Iterable<T>> query<T extends BaseDocument>(
      String path, Query query, String resultSet, Context context) {
    final call = HttpCall.post(path);
    return _send(
            call,
            query,
            context.copyWith(
              paging: query,
              partition: query.partition,
              headers: HttpHeader.queryPayload,
            ))
        .then((result) => _buildMany<T>(context, result![resultSet]))
        .rethrowContextualizedException(call);
  }

  Future<dynamic> rawQuery(
      String path, Query query, String resultSet, Context context) {
    final call = HttpCall.post(path);
    return _send(
        call,
        query,
        context.copyWith(
          paging: query,
          partition: query.partition,
          headers: HttpHeader.queryPayload,
        )).rethrowContextualizedException(call);
  }

  Future<T> put<T extends BaseDocument>(
      String path, BaseDocument doc, Context context) {
    final call = HttpCall.put(path);
    return _send(call, doc, context)
        .then((data) => _build<T>(context, data)!)
        .rethrowContextualizedException(call);
  }

  Future<bool> delete(String path, Context context) {
    final call = HttpCall.delete(path);
    return _send(call, null, context)
        .then((result) => true)
        .rethrowContextualizedException(call);
  }
}
