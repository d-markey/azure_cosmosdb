import 'index_order.dart';

/// Class representing an index.
class IndexPath {
  IndexPath(this.path, {this.order});

  /// JSON path to the field/nodes.
  final String path;

  /// Index order, see constants from [IndexOrder].
  final IndexOrder? order;

  /// Serializes this instance to a JSON object.
  Map<String, dynamic> toJson() => {
        'path': path,
        if (order != null) 'order': order!.name,
      };

  /// Deserializes data from JSON object [json] into a new [IndexPath] instance.
  static IndexPath fromJson(Map json) =>
      IndexPath(json['path'], order: IndexOrder.tryParse(json['order']));
}
