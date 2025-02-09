/// Constants for index ordering.
class IndexOrder {
  const IndexOrder._(this.name);

  final String name;

  /// Ascending order.
  static const ascending = IndexOrder._('ascending');

  /// Descending order.
  static const descending = IndexOrder._('descending');

  static final _values = {
    ascending.name: ascending,
    descending.name: descending
  };

  /// Returns the [IndexOrder] constant corresponding to the specified [order].
  static IndexOrder? tryParse(String? order) => _values[order];
}
