import '../cosmos_db_exceptions.dart';
import '_path_component.dart';
import '_path_parser_state.dart';

class PathParser {
  static List<PathComponent> parse(String path) {
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
