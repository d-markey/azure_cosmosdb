/// Function definition to hydrate (deserialize) CosmosDB documents.
typedef DocumentBuilder<T extends BaseDocument> = T Function(Map json);

/// Base class for CosmosDB documents.
abstract class BaseDocument {
  /// The document's [id].
  dynamic get id;

  /// Serialization to a JSON map.
  dynamic toJson();
}

/// Base class for query/patch documents.
abstract class SpecialDocument implements BaseDocument {
  @override
  String get id => '';
}

/// Base class for a document with an id.
class DocumentWithId implements BaseDocument {
  DocumentWithId(this.id);

  @override
  final dynamic id;

  @override
  dynamic toJson() => {'id': id};
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

/// Mixin to add custom partition key on [BaseDocument].
mixin PartitionKeyMixin on BaseDocument {
  /// The document's partition key. Override this to provide a custom partition
  /// key. By default, [id] is used as the partition key. When overriding,
  /// make sure this value is serialized in accordance with the container's
  /// partition key definition.
  List<dynamic> get keys => [id];
}

// For internal use
extension PartitionKeyExt on BaseDocument {
  List<dynamic> getKeys() =>
      (this is PartitionKeyMixin) ? (this as PartitionKeyMixin).keys : [id];
}
