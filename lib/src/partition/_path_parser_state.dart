import '../cosmos_db_exceptions.dart';
import '_path_component.dart';

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
