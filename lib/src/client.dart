import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '_authorization.dart';
import '_context.dart';

import 'base_document.dart';
import 'database.dart';
import 'exceptions.dart' as errors;
import 'paging.dart';
import 'permission.dart';
import 'query.dart';
import 'user.dart';

typedef DocumentBuilder<T extends BaseDocument> = T Function(Map json);
typedef _DocumentBuilder = DocumentBuilder<BaseDocument>;
typedef FutureCallback<T> = Future<T> Function();

class Client {
  Client(String urlOrAccount, {String? masterKey, http.Client? httpClient})
      : _url = _buildUrl(urlOrAccount),
        _http = httpClient ?? http.Client(),
        _key =
            (masterKey == null) ? null : Hmac(sha256, base64Decode(masterKey)) {
    registerBuilder<User>(User.build);
    registerBuilder<Permission>(Permission.build);
  }

  static String _buildUrl(String url) {
    if (!url.contains('://')) url = 'https://$url.documents.azure.com/';
    if (!url.endsWith('/')) url += '/';
    return url;
  }

  final String _url;
  final Hmac? _key;
  final http.Client _http;

  final _builders = <Type, _DocumentBuilder>{};

  void registerBuilder<T extends BaseDocument>(DocumentBuilder<T> builder) {
    _builders[T] = builder;
  }

  DocumentBuilder<T> _getBuilder<T extends BaseDocument>() {
    final builder = _builders[T];
    if (builder == null) throw Exception('Unknown document type $T');
    return (data) => builder(data) as T;
  }

  T? _build<T extends BaseDocument>(Map? item) {
    final builder = _getBuilder<T>();
    return (item == null || item.isEmpty) ? null : builder(item);
  }

  Iterable<T> _buildMany<T extends BaseDocument>(List? items) {
    final builder = _getBuilder<T>();
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

  Future<Map<String, dynamic>> _send(
    String method,
    String path,
    BaseDocument? body,
    Context context,
  ) async {
    String resId = context.resId ?? '';
    if (resId.isEmpty) {
      resId = path;
    }

    var auth = (context.token != null)
        ? Authorization.fromToken(context.token!)
        : Authorization(_key, method.toLowerCase(), context.type, resId);

    var result = await _sendWithAuth(method, path, body, context, auth);

    if (result.statusCode == 403) {
      // try to get a new permission from the onForbidden callback
      final permission = await context.onForbidden?.call();
      if (permission != null) {
        // try again with this permission
        auth = Authorization.fromToken(permission.token);
        result = await _sendWithAuth(method, path, body, context, auth);
      }
    }

    final contentType = result.headers['content-type'];
    if (contentType != 'application/json') {
      throw Exception('Unexpected response: $contentType');
    }
    final response = await result.stream.bytesToString();
    Map<String, dynamic> data = response.isEmpty ? {} : jsonDecode(response);

    if (result.statusCode < 200 || result.statusCode >= 300) {
      final msg = data['message'];
      switch (result.statusCode) {
        case 401:
          throw errors.UnauthorizedException(method, path, message: msg);
        case 403:
          throw errors.ForbiddenException(method, path, message: msg);
        case 404:
          if (context.throwOnNotFound) {
            throw errors.NotFoundException(method, path, message: msg);
          }
          return {};
        case 409:
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

    context.paging?.setContinuation(result.headers['x-ms-continuation']);
    return data;
  }

  Future<Map<String, dynamic>> getJson(String path, Context context) =>
      _send('GET', path, null, context);

  Future<T?> get<T extends BaseDocument>(String path, Context context) =>
      _send('GET', path, null, context).then((data) => _build<T>(data));

  Future<Iterable<T>> getMany<T extends BaseDocument>(
          String path, String resultSet, Context context) =>
      _send('GET', path, null, context)
          .then((result) => _buildMany<T>(result[resultSet]));

  Future<T> post<T extends BaseDocument>(
          String path, BaseDocument doc, Context context) =>
      _send('POST', path, doc, context).then((data) => _build<T>(data)!);

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
      ).then((result) => _buildMany<T>(result[resultSet]));

  Future<T> put<T extends BaseDocument>(
          String path, BaseDocument doc, Context context) =>
      _send('PUT', path, doc, context).then((data) => _build<T>(data)!);

  Future<bool> delete<T extends BaseDocument>(String path, Context context) =>
      _send('DELETE', path, null, context).then((data) => true);

  Database getDatabase(String db) => Database(this, db);
}
