import '../cosmos_db_exceptions.dart';

class PathParser {
  List<PathComponent> parse(String path) {
    final state = ParserState(path);
    final components = <PathComponent>[];
    while (state.current.isNotEmpty) {
      switch (state.current) {
        case '/':
          components.add(state.getPathSegment());
          break;
        case '[':
          components.add(state.getArrayIndex());
          break;
        default:
          throw InvalidTokenException(
              'Unexpected token ${state.current}; expecting "/" or "[".');
      }
    }
    return components;
  }
}

class ParserState {
  ParserState(String path)
      : _chars = path.runes.map((r) => String.fromCharCode(r)).toList();

  final List<String> _chars;
  int _pos = 0;

  String get current => (_pos < _chars.length) ? _chars[_pos] : '';

  PathSegment getPathSegment() {
    if (current == '/') {
      _pos++;
    }
    var start = _pos, end = -1;
    if (current == '"') {
      start++;
      _pos++;
      while (_pos < _chars.length) {
        if (current == '"') {
          end = _pos;
          _pos++;
          break;
        }
        _pos++;
      }
    } else {
      while (_pos < _chars.length) {
        if (const {'/', '['}.contains(current)) {
          end = _pos;
          break;
        }
        _pos++;
      }
    }
    if (end < 0) {
      end = _pos;
    }
    return PathSegment(_chars.sublist(start, end).join().trim());
  }

  ArrayIndex getArrayIndex() {
    _pos++;
    var start = _pos, end = -1;
    while (_pos < _chars.length) {
      if (current == ']') {
        end = _pos;
        _pos++;
        break;
      }
      _pos++;
    }
    if (end < 0) {
      throw InvalidTokenException('Missing token: "]".');
    }
    final idx = int.tryParse(_chars.sublist(start, end).join());
    if (idx == null) {
      throw InvalidTokenException('Integer value expected in array accessor.');
    }
    return ArrayIndex(idx);
  }
}

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
