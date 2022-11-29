class IndexPath {
  IndexPath(this.path, {this.order});

  final String path;
  final String? order;

  Map<String, dynamic> toJson() => {
        'path': path,
        if (order != null) 'order': order,
      };
}
