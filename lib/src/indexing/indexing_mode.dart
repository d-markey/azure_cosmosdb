/// Constants for indexing modes.
class IndexingMode {
  const IndexingMode._(this.name);

  final String name;

  /// Consistent mode.
  static const consistent = IndexingMode._('consistent');

  /// Lazy mode. Lazy indexing is not supported in serverless mode, and new
  /// containers cannot select lazy indexing unless an exemption was granted
  /// by Microsoft.
  @Deprecated(
      'Lazy indexing is not supported in serverless mode, and new containers cannot select lazy indexing unless an exemption was granted by Microsoft')
  static const lazy = IndexingMode._('lazy');

  /// No indexing.
  static const none = IndexingMode._('none');

  // ignore: deprecated_member_use_from_same_package
  static final _values = {
    consistent.name: consistent,
    // ignore: deprecated_member_use_from_same_package
    lazy.name: lazy,
    none.name: none
  };

  /// Returns the [IndexingMode] constant corresponding to the specified [mode].
  static IndexingMode? tryParse(String? mode) => _values[mode];
}
