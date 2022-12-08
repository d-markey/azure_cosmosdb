import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';

import '../_internal/_authorization.dart';
import '../_internal/_http_status_codes.dart';
import '../base_document.dart';
import '../cosmos_db_exceptions.dart';
import '../queries/paging.dart';
import '../queries/query.dart';
import '_context.dart';
import '_retry_if_web.dart' if (dart.library.io) '_retry_if_vm.dart';

typedef _DocumentBuilder = DocumentBuilder<BaseDocument>;

class Client {
  Client(this._url, {String? masterKey, http.Client? httpClient})
      : _baseHttpClient = httpClient ?? http.Client() {
    _http = _baseHttpClient;
    if (masterKey != null) {
      _key = crypto.Hmac(crypto.sha256, base64Decode(masterKey));
    } else {
      _key = null;
    }
  }

  final String _url;
  final http.Client _baseHttpClient;
  final RetryOptions _retry = RetryOptions();

  late final crypto.Hmac? _key;
  late final http.Client _http;

  final _builders = <Type, _DocumentBuilder>{};

  http.Client get httpClient => _baseHttpClient;

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
    String method,
    String path,
    BaseDocument? body,
    Context context,
    Authorization authorization,
  ) {
    final request = http.Request(method, Uri.parse(_url + path));

    if (body != null) {
      request.body = jsonEncode(body);
      request.headers['content-type'] = 'application/json';
    }

    request.headers.addAll(context.getHeaders());

    request.headers['authorization'] = authorization.token;
    request.headers['x-ms-date'] = authorization.date;
    request.headers['x-ms-version'] = '2018-12-31';

    return _retry.retry(
      () => _http.send(request).timeout(Duration(seconds: 5)),
      retryIf: (e) => retryIf(_http, e),
    );
  }

  Future<dynamic> _send(
    String method,
    String path,
    BaseDocument? body,
    Context context,
  ) async {
    String resId = context.resId ?? path;

    var auth = (context.token != null)
        ? Authorization.fromToken(context.token!)
        : Authorization.fromKey(
            _key, method.toLowerCase(), context.type, resId);

    var result = await _sendWithAuth(method, path, body, context, auth);

    if (result.statusCode == HttpStatusCode.forbidden) {
      // try to get a new permission from the onForbidden callback
      final permission = await context.onForbidden?.call();
      final token = permission?.token;
      if (token != null) {
        // try again with this permission
        auth = Authorization.fromToken(token);
        result = await _sendWithAuth(method, path, body, context, auth);
      }
    }

    final contentType = result.headers['content-type'];
    if (contentType != 'application/json') {
      throw BadResponseException('Unsupported content-type: $contentType');
    }
    final response = await result.stream.bytesToString();
    dynamic data = response.isEmpty ? {} : jsonDecode(response);

    if (!HttpStatusCode.success(result.statusCode)) {
      final ex = CosmosDbException(result.statusCode, data['message']);
      if (ex is! NotFoundException || context.throwOnNotFound) {
        throw ex;
      }
      // set data to null when ignoring the error
      data = null;
    }

    context.paging?.setContinuation(result.headers['x-ms-continuation'] ?? '');
    return data;
  }

  Future<dynamic> getJson(String path, Context context) =>
      _send('GET', path, null, context).onError<ContextualizedException>(
          (error, stackTrace) => throw error.withContext('GET', path));

  Future<T?> get<T extends BaseDocument>(String path, Context context) =>
      _send('GET', path, null, context)
          .then((data) => _build<T>(context, data))
          .onError<ContextualizedException>(
              (error, stackTrace) => throw error.withContext('GET', path));

  Future<Iterable<T>> getMany<T extends BaseDocument>(
          String path, String resultSet, Context context) =>
      _send('GET', path, null, context)
          .then((result) => _buildMany<T>(context, result![resultSet]))
          .onError<ContextualizedException>(
              (error, stackTrace) => throw error.withContext('GET', path));

  Future<T> post<T extends BaseDocument>(
          String path, BaseDocument doc, Context context) =>
      _send('POST', path, doc, context)
          .then((data) => _build<T>(context, data)!)
          .onError<ContextualizedException>(
              (error, stackTrace) => throw error.withContext('POST', path));

  Future<Iterable<T>> query<T extends BaseDocument>(
          String path, Query query, String resultSet, Context context) =>
      _send(
        'POST',
        path,
        query,
        context.copyWith(
          query: query,
          headers: {
            'content-type': 'application/query+json',
            'x-ms-documentdb-isquery': 'true',
          },
        ),
      )
          .then((result) => _buildMany<T>(context, result![resultSet]))
          .onError<ContextualizedException>(
              (error, stackTrace) => throw error.withContext('POST', path));

  Future<dynamic> rawQuery(
          String path, Query query, String resultSet, Context context) =>
      _send(
        'POST',
        path,
        query,
        context.copyWith(
          query: query,
          headers: {
            'content-type': 'application/query+json',
            'x-ms-documentdb-isquery': 'true',
          },
        ),
      ).onError<ContextualizedException>(
          (error, stackTrace) => throw error.withContext('POST', path));

  Future<T> put<T extends BaseDocument>(
          String path, BaseDocument doc, Context context) =>
      _send('PUT', path, doc, context)
          .then((data) => _build<T>(context, data)!)
          .onError<ContextualizedException>(
              (error, stackTrace) => throw error.withContext('PUT', path));

  Future<bool> delete(String path, Context context) =>
      _send('DELETE', path, null, context)
          .then((result) => true)
          .onError<ContextualizedException>(
              (error, stackTrace) => throw error.withContext('DELETE', path));
}
