class SpatialIndexPath {
  SpatialIndexPath(this.path, {Iterable<String>? types}) {
    if (types != null) {
      this.types.addAll(types);
    }
  }

  final String path;
  final types = <String>[];

  Map<String, dynamic> toJson() => {
        'path': path,
        if (types.isNotEmpty) 'types': types,
      };
}
