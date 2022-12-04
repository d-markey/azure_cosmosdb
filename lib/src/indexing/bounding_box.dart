/// Class representing a bounding box for spatial indexing.
class BoundingBox {
  BoundingBox(this.xmin, this.ymin, this.xmax, this.ymax);

  final double xmin;
  final double ymin;
  final double xmax;
  final double ymax;

  Map<String, dynamic> toJson() => {
        'xmin': xmin,
        'ymin': ymin,
        'xmax': xmax,
        'ymax': ymax,
      };
}
