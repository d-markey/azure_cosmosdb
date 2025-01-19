/// Function definition to hydrate (deserialize) CosmosDB documents.
typedef DocumentBuilder<T extends BaseDocument> = T Function(Map json);

/// Base class for CosmosDB documents.
abstract class BaseDocument {
  /// The document's [id].
  Object get id;

  /// Serializes this instance to a JSON object.
  dynamic toJson();
}

/// Base class for CosmosDB documents including the `etag` property.
abstract class BaseDocumentWithEtag extends BaseDocument with EtagMixin {}

/// Base class for CosmosDB documents including the `etag` property.
mixin EtagMixin on BaseDocument {
  /// The document's `etag` property.
  String get etag => _etag ?? '';
  String? _etag;

  /// Set `etag` from a JSON map; to be called by [DocumentBuilder] methods.
  void setEtag(Map json) => _etag = json['_etag'];
}

/// Internal use: base class for query/patch/batch requests.
abstract class SpecialDocument implements BaseDocument {
  @override
  final String id = '';
}
