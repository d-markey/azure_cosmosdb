/// Function definition to hydrate (deserialize) CosmosDB documents.
typedef DocumentBuilder<T extends BaseDocument> = T Function(Map json);

/// Base class for CosmosDB documents.
abstract class BaseDocument {
  /// The document's [id].
  String get id;

  /// Serialization to a JSON map.
  Map<String, dynamic> toJson();
}

/// Base class for CosmosDB documents including the `etag` property.
abstract class BaseDocumentWithEtag extends BaseDocument {
  /// The document's `etag` property.
  String get etag => _etag ?? '';
  String? _etag;

  /// Set `etag` from a JSON map; to be called by [DocumentBuilder] methods.
  void setEtag(Map body) => _etag = body['_etag'];
}
