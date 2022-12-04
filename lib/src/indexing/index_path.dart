import 'index_order.dart';

/// Class representing an index.
class IndexPath {
  IndexPath(this.path, {this.order});

  /// JSON path to the field/nodes.
  final String path;

  /// Index order, see constants from [IndexOrder].
  final IndexOrder? order;

  Map<String, dynamic> toJson() => {
        'path': path,
        if (order != null) 'order': order!.name,
      };
}
