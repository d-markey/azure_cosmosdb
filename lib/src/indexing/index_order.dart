/// Constants for index ordering.
class IndexOrder {
  const IndexOrder._(this.name);

  final String name;

  /// Ascending order.
  static const ascending = IndexOrder._('ascending');

  /// Descending order.
  static const descending = IndexOrder._('descending');
}
