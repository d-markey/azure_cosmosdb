import '../_internal/_extensions.dart';

/// Constants for index ordering.
class IndexOrder {
  const IndexOrder._(this.name);

  final String name;

  /// Ascending order.
  static const ascending = IndexOrder._('ascending');

  /// Descending order.
  static const descending = IndexOrder._('descending');

  static const _orders = [ascending, descending];

  /// Returns the [IndexOrder] constant corresponding to the specified [order].
  static IndexOrder? tryParse(dynamic order) =>
      _orders.firstOrDefault((m) => m.name == order);
}
