// Indexing modes
class IndexingMode {
  static const consistent = 'consistent';
  @Deprecated(
      'Lazy indexing is not supported in serverless mode, and new containers cannot select lazy indexing unless an exemption was granted by Microsoft')
  static const lazy = 'lazy';
  static const none = 'none';
}

// Index orders for composite indexes
class IndexOrder {
  static const ascending = 'ascending';
  static const descending = 'descending';
}

// Spatial index types
class SpatialIndexType {
  static const point = 'point';
  static const polygon = 'polygon';
  static const multiPolygon = 'multiPolygon';
  static const lineString = 'lineString';
}

// Index data types
class DataType {
  static const string = 'string';
  static const number = 'number';
}
