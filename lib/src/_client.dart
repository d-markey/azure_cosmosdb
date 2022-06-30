import 'dart:convert';

import 'package:azure_cosmosdb/src/_http_status_codes.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '_authorization.dart';
import '_context.dart';

import 'base_document.dart';
import 'exceptions.dart' as errors;
import 'paging.dart';
import 'query.dart';

typedef _DocumentBuilder = DocumentBuilder<BaseDocument>;

class Client {
  Client(this._url, {String? masterKey, http.Client? httpClient})
      : _http = httpClient ?? http.Client(),
        _key = masterKey?.deriveHmac(sha256);

  final String _url;
  final Hmac? _key;
  final http.Client _http;

  final _builders = <Type, _DocumentBuilder>{};

  void registerBuilder<T extends BaseDocument>(DocumentBuilder<T> builder) {
    _builders[T] = builder;
  }

  DocumentBuilder<T> _getBuilder<T extends BaseDocument>(Context context) {
    final builder = context.builder ?? _builders[T];
    if (builder == null) throw Exception('Unknown document type $T');
    return (data) => builder(data) as T;
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

    return _http.send(request);
  }

  Future<Map<String, dynamic>?> _send(
    String method,
    String path,
    BaseDocument? body,
    Context context,
  ) async {
    String resId = context.resId ?? path;

    var auth = (context.token != null)
        ? Authorization.fromToken(context.token!)
        : Authorization(_key, method.toLowerCase(), context.type, resId);

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
      throw Exception('Unexpected response: $contentType');
    }
    final response = await result.stream.bytesToString();
    Map<String, dynamic> data = response.isEmpty ? {} : jsonDecode(response);

    if (!HttpStatusCode.success(result.statusCode)) {
      final msg = data['message'];
      switch (result.statusCode) {
        case HttpStatusCode.unauthorized:
          throw errors.UnauthorizedException(method, path, message: msg);
        case HttpStatusCode.forbidden:
          throw errors.ForbiddenException(method, path, message: msg);
        case HttpStatusCode.notFound:
          if (context.throwOnNotFound) {
            throw errors.NotFoundException(method, path, message: msg);
          }
          return null;
        case HttpStatusCode.conflict:
          throw errors.ConflictException(method, path, message: msg);
        default:
          throw errors.Exception(
            method,
            path,
            result.statusCode,
            msg ?? 'Error ${result.statusCode}',
          );
      }
    }

    context.paging?.setContinuation(result.headers['x-ms-continuation'] ?? '');
    return data;
  }

  Future<Map<String, dynamic>?> getJson(String path, Context context) =>
      _send('GET', path, null, context);

  Future<T?> get<T extends BaseDocument>(String path, Context context) =>
      _send('GET', path, null, context)
          .then((data) => _build<T>(context, data));

  Future<Iterable<T>> getMany<T extends BaseDocument>(
          String path, String resultSet, Context context) =>
      _send('GET', path, null, context)
          .then((result) => _buildMany<T>(context, result![resultSet]));

  Future<T> post<T extends BaseDocument>(
          String path, BaseDocument doc, Context context) =>
      _send('POST', path, doc, context)
          .then((data) => _build<T>(context, data)!);

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
      ).then((result) => _buildMany<T>(context, result![resultSet]));

  Future<T> put<T extends BaseDocument>(
          String path, BaseDocument doc, Context context) =>
      _send('PUT', path, doc, context)
          .then((data) => _build<T>(context, data)!);

  Future<bool> delete(String path, Context context) =>
      _send('DELETE', path, null, context).then((result) => true);
}

extension _HmacExt on String {
  Hmac deriveHmac(Hash hash) => Hmac(hash, base64Decode(this));
}
