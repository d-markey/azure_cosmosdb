import '../_internal/_http_header.dart';
import '../base_document.dart';
import '../indexing/partition.dart';
import '../permissions/cosmos_db_permission.dart';
import '../queries/paging.dart';
import '../cosmos_db_server.dart';

const version = '1.8.0';

class Context {
  Context({
    required this.type,
    this.resId,
    Map<String, String>? headers,
    this.throwOnNotFound = true,
    this.paging,
    this.partition,
    this.token,
    this.onForbidden,
    this.builder,
  }) {
    if (headers != null) {
      _headers = {...headers};
    }
  }

  final String type;
  final String? resId;
  final bool throwOnNotFound;
  final Paging? paging;
  final CosmosDbPartition? partition;
  final String? token;
  final FutureCallback<CosmosDbPermission?>? onForbidden;
  final DocumentBuilder? builder;

  Map<String, String>? _headers;

  void addHeader(String name, String value) => (_headers ??= {})[name] = value;

  Context copyWith(
      {Paging? paging,
      CosmosDbPartition? partition,
      Map<String, String>? headers,
      List<String>? removeHeaders}) {
    final copy = Context(
      type: type,
      resId: resId,
      paging: paging ?? this.paging,
      partition: partition ?? this.partition,
      token: token,
      onForbidden: onForbidden,
    );
    if (_headers != null) {
      (copy._headers ??= {}).addAll(_headers!);
    }
    if (headers != null) {
      (copy._headers ??= {}).addAll(headers);
    }
    if (removeHeaders != null) {
      copy._headers?.removeWhere((key, value) => removeHeaders.contains(key));
    }
    return copy;
  }

  Map<String, String> getHeaders() {
    final headers = {HttpHeader.userAgent: 'AzureCosmosDb.Dart/$version'};
    if (_headers != null) {
      headers.addAll(_headers!);
    }
    final partitionHeader = partition?.header;
    if (partitionHeader != null) {
      headers.addAll(partitionHeader);
    }
    final maxCount = (paging?.maxCount ?? -1);
    if (maxCount > 0) {
      headers[HttpHeader.msMaxItemCount] = maxCount.toString();
    }
    final continuation = paging?.continuation ?? '';
    if (continuation.isNotEmpty) {
      headers[HttpHeader.msContinuation] = continuation;
    }
    return headers;
  }
}
