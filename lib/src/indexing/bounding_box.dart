/// Class representing a bounding box for spatial indexing.
class BoundingBox {
  BoundingBox(this.xmin, this.ymin, this.xmax, this.ymax);

  /// The [xmin] coordinate of this instance.
  final num xmin;

  /// The [ymin] coordinate of this instance.
  final num ymin;

  /// The [xmax] coordinate of this instance.
  final num xmax;

  /// The [ymax] coordinate of this instance.
  final num ymax;

  /// Serializes this instance to a JSON object.
  Map<String, dynamic> toJson() => {
        'xmin': xmin,
        'ymin': ymin,
        'xmax': xmax,
        'ymax': ymax,
      };

  /// Deserializes data from JSON object [json] into a new [BoundingBox] instance.
  static BoundingBox fromJson(Map json) =>
      BoundingBox(json['xmin'], json['ymin'], json['xmax'], json['ymax']);
}
