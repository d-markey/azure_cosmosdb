import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';

import '../_internal/_http_call.dart';
import '../_internal/_http_header.dart';
import '../_internal/_mime_type.dart';
import '../access_control/cosmos_db_access_control.dart';
import '../access_control/cosmos_db_authorization.dart';
import '../base_document.dart';
import '../batch/batch_operation.dart';
import '../batch/batch_response.dart';
import '../batch/transactional_batch.dart';
import '../cosmos_db_exceptions.dart';
import '../partition/partition_key_range.dart';
import '../queries/paging.dart';
import '../queries/query.dart';
import '_context.dart';
import '_retry_if_web.dart' if (dart.library.io) '_retry_if_vm.dart';
import 'features.dart';
import 'http_status_codes.dart';

class Client {
  Client(
    this._url, {
    String? masterKey,
    this.multipleWriteLocations = false,
    http.Client? httpClient,
    RetryOptions? retryOptions,
    required this.version,
  })  : httpClient = httpClient ?? http.Client(),
        _retry = retryOptions ?? RetryOptions(),
        features = Features.getFeatures(version) {
    if (masterKey != null) {
      _key = crypto.Hmac(crypto.sha256, base64Decode(masterKey));
    } else {
      _key = null;
    }
  }

  final String version;
  final Features features;

  final String _url;
  final bool multipleWriteLocations;
  final RetryOptions _retry;

  late final crypto.Hmac? _key;
  late final http.Client httpClient;

  T? _build<T extends BaseDocument>(Context context, Map? item) {
    if (item == null) {
      return null;
    }
    final builder = context.getBuilder<T>();
    return builder(item);
  }

  Iterable<T> _buildMany<T extends BaseDocument>(Context context, List? items) {
    if (items == null) {
      return const [];
    }
    final builder = context.getBuilder<T>();
    return items.map((item) => builder(item));
  }

  Future<http.StreamedResponse> _sendWithAuth(
    HttpCall call,
    BaseDocument? document,
    Context context,
    CosmosDbAccessControl accessControl,
  ) {
    return _retry.retry(
      () {
        final request = call.getRequest(_url, accessControl);

        if (document != null) {
          request.headers.addAll(HttpHeader.jsonPayload);
          request.body = jsonEncode(document);
        }
        if (multipleWriteLocations && !call.method.isReadOnly) {
          request.headers.addAll(HttpHeader.allowTentativeWrites);
        }

        request.headers.addAll(context.getHeaders());
        return httpClient.send(request).timeout(Duration(seconds: 5));
      },
      retryIf: (e) => retryIf(httpClient, e),
    );
  }

  Future<dynamic> _send(
    HttpCall call,
    BaseDocument? document,
    Context context,
  ) async {
    String resId = context.resId ?? call.uri;

    final accessControl = context.accessControl ??
        CosmosDbAuthorization.fromKey(
          _key,
          call.method.name.toLowerCase(),
          context.type,
          resId,
        );

    var result = await _sendWithAuth(call, document, context, accessControl);

    switch (result.statusCode) {
      case HttpStatusCode.unauthorized:
      case HttpStatusCode.invalidToken:
      case HttpStatusCode.forbidden:
        // try to get a new authorization from the refreshAccessControl callback
        final newAuth = await context.refreshAccessControl
            ?.call(result.statusCode, accessControl);
        if (newAuth != null) {
          // try again with this authorization
          result = await _sendWithAuth(call, document, context, newAuth);
        }
        break;
      case HttpStatusCode.tooManyRequests:
        // throttling, retry after the specified delay
        final delay =
            int.tryParse(result.headers[HttpHeader.msRetryAfterMs] ?? '');
        if (delay != null) {
          await Future.delayed(Duration(milliseconds: delay));
          result = await _sendWithAuth(call, document, context, accessControl);
        }
        break;
      case HttpStatusCode.serviceUnavailable:
        // retry once
        await Future.delayed(Duration(milliseconds: 250));
        result = await _sendWithAuth(call, document, context, accessControl);
        break;
      case HttpStatusCode.noContent:
        // no content: return null (https://github.com/d-markey/azure_cosmosdb/issues/1)
        return null;
    }

    dynamic data;

    final length = int.tryParse(result.headers[HttpHeader.contentLength] ?? '');
    if (length == null || length > 0) {
      // only check content-type and parse body if content-length > 0
      final contentType = result.headers[HttpHeader.contentType];
      if (contentType != MimeType.json) {
        throw BadResponseException('Unsupported content-type: $contentType.');
      }
      final response = await result.stream.bytesToString();
      data = response.isEmpty ? {} : jsonDecode(response);
    }

    if (!HttpStatusCode.isSuccess(result.statusCode)) {
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

  Future<dynamic> rawGet(String path, Context context) {
    final call = HttpCall.get(path, version);
    return _send(call, null, context).rethrowContextualizedException(call);
  }

  Future<T?> get<T extends BaseDocument>(String path, Context context) {
    final call = HttpCall.get(path, version);
    return _send(call, null, context)
        .then((data) => _build<T>(context, data))
        .rethrowContextualizedException(call);
  }

  Future<Iterable<T>> getMany<T extends BaseDocument>(
      String path, String resultSet, Context context) {
    final call = HttpCall.get(path, version);
    return _send(call, null, context)
        .then((result) => _buildMany<T>(context, result![resultSet]))
        .rethrowContextualizedException(call);
  }

  Future<Iterable<T>> query<T extends BaseDocument>(
      String path, Query query, String resultSet, Context context) {
    final call = HttpCall.post(path, version);
    return _send(
            call,
            query,
            context.copyWith(
              paging: query,
              partitionKey: query.partitionKey,
              headers: HttpHeader.queryPayload,
            ))
        .then((result) => _buildMany<T>(context, result![resultSet]))
        .rethrowContextualizedException(call);
  }

  Future<dynamic> rawQuery(
      String path, Query query, String resultSet, Context context) {
    final call = HttpCall.post(path, version);
    return _send(
        call,
        query,
        context.copyWith(
          paging: query,
          partitionKey: query.partitionKey,
          headers: HttpHeader.queryPayload,
        )).rethrowContextualizedException(call);
  }

  Future<BatchResponse> batch(String path, TransactionalBatch batch,
      List<PartitionKeyRange> pkRanges, Context context) async {
    if (batch.operations.isEmpty) {
      return BatchResponse();
    } else {
      final call = HttpCall.post(path, version);
      final response = await _send(
              call,
              batch,
              context.copyWith(
                headers: batch.getHeaders(pkRanges),
              ))
          .then((data) =>
              BatchResponseInternalExt.build(data, batch.operations, context))
          .rethrowContextualizedException(call);
      // check results, some operations may require a replay
      List<BatchOperation>? retryOps;
      int? retryAfterMs;
      for (var r in response.results) {
        var retry = r.retryAfterMs ?? 0;
        if (retry > 0) {
          retryOps ??= <BatchOperation>[];
          retryOps.add(r.operation);
          if (retryAfterMs == null || retry > retryAfterMs) {
            retryAfterMs = retry;
          }
        }
      }
      if (retryOps != null) {
        // re-run operations
        await Future.delayed(Duration(milliseconds: retryAfterMs!));
        final replay = batch.clone();
        for (var op in retryOps) {
          op.clearResult();
          replay.add(op);
        }
        final newResults = await this.batch(path, replay, pkRanges, context);
        response.update(newResults);
      }
      return response;
    }
  }

  Future<T> post<T extends BaseDocument>(
      String path, BaseDocument doc, Context context) {
    final call = HttpCall.post(path, version);
    return _send(call, doc, context)
        .then((data) => _build<T>(context, data)!)
        .rethrowContextualizedException(call);
  }

  Future<T> patch<T extends BaseDocument>(
      String path, BaseDocument doc, Context context) {
    final call = HttpCall.patch(path, version);
    return _send(call, doc, context.copyWith(headers: HttpHeader.patchPayload))
        .then((data) => _build<T>(context, data)!)
        .rethrowContextualizedException(call);
  }

  Future<T> put<T extends BaseDocument>(
      String path, BaseDocument doc, Context context) {
    final call = HttpCall.put(path, version);
    return _send(call, doc, context)
        .then((data) => _build<T>(context, data)!)
        .rethrowContextualizedException(call);
  }

  Future<bool> delete(String path, Context context) {
    final call = HttpCall.delete(path, version);
    return _send(call, null, context)
        .then((result) => true)
        .rethrowContextualizedException(call);
  }
}
