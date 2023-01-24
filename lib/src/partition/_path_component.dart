abstract class PathComponent {
  dynamic extract(dynamic json);
}

class PathSegment extends PathComponent {
  PathSegment(this.segment);

  final String segment;

  @override
  dynamic extract(dynamic json) => (json as Map)[segment];

  @override
  int get hashCode => segment.hashCode;

  @override
  bool operator ==(dynamic other) =>
      (other is PathSegment) && segment == other.segment;
}

class ArrayIndex extends PathComponent {
  ArrayIndex(this.index);

  final int index;

  @override
  dynamic extract(dynamic json) => (json as List)[index];

  @override
  int get hashCode => index;

  @override
  bool operator ==(dynamic other) =>
      (other is ArrayIndex) && index == other.index;
}

extension JsonExtractExt on List<PathComponent> {
  dynamic extract(dynamic json) {
    var cur = json;
    for (var i = 0; i < length; i++) {
      cur = this[i].extract(cur);
    }
    return cur;
  }
}
