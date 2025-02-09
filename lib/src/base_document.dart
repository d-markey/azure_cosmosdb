/// Function definition to hydrate (deserialize) CosmosDB documents.
typedef JSonMessage = Map<String, dynamic>;
typedef DocumentBuilder<T extends BaseDocument> = T Function(JSonMessage json);

abstract class CosmosDbDocument {
  dynamic toJson();
}

/// Internal use: base class for query/patch/batch requests.
abstract class SpecialDocument extends CosmosDbDocument {}

/// Base class for CosmosDB documents.
abstract class BaseDocument extends CosmosDbDocument {
  /// The document's [id].
  Object get id;

  /// Serializes this instance to a JSON object.
  @override
  JSonMessage toJson();
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

/// Base class for CosmosDB documents including the `etag` property.
class Document extends BaseDocumentWithEtag {
  Document(this.id, JSonMessage json) {
    _json.addAll(json);
    _json['id'] = id;
  }

  @override
  final String id;

  final JSonMessage _json = {};

  dynamic getProp(String key) => _json[key];

  @override
  JSonMessage toJson() => {
        if (_etag?.isNotEmpty ?? false) '_etag': _etag,
        ..._json,
      };

  static Document fromJson(JSonMessage json) =>
      Document(json['id'], json)..setEtag(json);
}
