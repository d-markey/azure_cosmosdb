import '../base_document.dart';
import 'tokenizer.dart';
import 'patch_operation.dart';

class Patch extends SpecialDocument {
  String? _condition;
  final _ops = <PatchOperation>[];
  Map<String, dynamic>? _parameters;

  void setCondition(String condition) => _condition = condition;

  void withParam(String name, dynamic value) =>
      (_parameters ??= {})[name] = value;

  String _getCondition() {
    var cond = _condition!;
    if (_parameters != null) {
      final parser = Tokenizer(cond);
      final parts = <String>[];
      var needSpace = false;
      for (var token in parser.getTokens(_parameters)) {
        switch (token.type) {
          case Token.parameterValue:
          case Token.identifier:
            if (needSpace) {
              parts.add(' ');
            }
            parts.add(token.text);
            needSpace = true;
            break;
          case Token.number:
          case Token.string:
            if (needSpace) {
              parts.add(' ');
            }
            parts.add(token.text);
            needSpace = true;
            break;
          case Token.separator:
            parts.add(token.text);
            needSpace = (token.text == ',' || token.text == ':');
            break;
          case Token.operator:
            needSpace = (token.text != '.');
            if (needSpace) {
              parts.add(' ');
            }
            parts.add(token.text);
            break;
        }
      }
      if (parts.isNotEmpty && parts.last == ' ') {
        parts.removeLast();
      }
      cond = parts.join();
    }
    return cond;
  }

  void add(String path, dynamic value) =>
      _ops.add(PatchOperation.add(path, value));

  void set(String path, dynamic value) =>
      _ops.add(PatchOperation.set(path, value));

  void replace(String path, dynamic value) =>
      _ops.add(PatchOperation.replace(path, value));

  void increment(String path, [num value = 1]) =>
      _ops.add(PatchOperation.incr(path, value));

  void decrement(String path, [num value = 1]) =>
      _ops.add(PatchOperation.decr(path, value));

  void remove(String path) => _ops.add(PatchOperation.remove(path));

  @override
  String get id => '';

  @override
  Map<String, dynamic> toJson() => {
        if (_condition != null) 'condition': _getCondition(),
        'operations': _ops.map((o) => o.toJson()).toList(),
      };
}
