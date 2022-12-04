import '../base_document.dart';
import '../indexing/partition.dart';
import '../permissions/cosmos_db_permission.dart';
import '../queries/paging.dart';
import '../queries/query.dart';
import '../cosmos_db_server.dart';

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
      _headers ??= {};
      _headers!.addAll(headers);
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

  void addHeader(String name, String value) {
    _headers ??= {};
    _headers![name] = value;
  }

  Context copyWith({Query? query, Map<String, String>? headers}) {
    final copy = Context(
        type: type,
        resId: resId,
        paging: paging ?? query,
        partition: partition ?? query?.partition,
        token: token,
        onForbidden: onForbidden);
    if (_headers != null) {
      copy._headers ??= {};
      copy._headers!.addAll(_headers!);
    }
    if (headers != null) {
      copy._headers ??= {};
      copy._headers!.addAll(headers);
    }
    return copy;
  }

  Map<String, String> getHeaders() {
    final headers = <String, String>{};
    if (_headers != null) {
      headers.addAll(_headers!);
    }
    final partitionHeader = partition?.header;
    if (partitionHeader != null) {
      headers[partitionHeader.key] = partitionHeader.value;
    }
    final maxCount = (paging?.maxCount ?? -1);
    if (maxCount > 0) {
      headers['x-ms-max-item-count'] = maxCount.toString();
    }
    final continuation = paging?.continuation ?? '';
    if (continuation.isNotEmpty) {
      headers['x-ms-continuation'] = continuation;
    }
    return headers;
  }
}
