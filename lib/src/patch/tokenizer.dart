import 'dart:convert';

import '../cosmos_db_exceptions.dart';

class Token {
  Token(this.text, this.type);

  final String text;
  final int type;

  static const number = 1;
  static const string = 2;
  static const operator = 3;
  static const separator = 4;
  static const identifier = 5;
  static const parameterValue = 6;
}

class Tokenizer {
  Tokenizer(this.condition)
      : _chars = condition.runes.map((r) => String.fromCharCode(r)).toList();

  final String condition;
  final List<String> _chars;

  String operator [](int idx) =>
      (0 <= idx && idx < _chars.length) ? _chars[idx] : '\u0000';

  static final _whitespaces =
      ' \t\n\v\f\r\u0085\u00A0\u1680\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200A\u2028\u2029\u202F\u205F\u3000'
          .split('')
          .toSet();
  static final _quotes = '\'"'.split('').toSet();
  static final _operators = '+-*/%&|^.?!=<>'.split('').toSet();
  static final _separators = '()[]{},:'.split('').toSet();

  static final _signs = '+-'.split('').toSet();
  static final _digits = '0123456789'.split('').toSet();
  static final _expMarks = 'Ee'.split('').toSet();
  static final _hexMarks = 'Xx'.split('').toSet();
  static final _hexDigits = '0123456789ABCDEFabcdef'.split('').toSet();

  static final _delimitors = {
    ..._whitespaces,
    ..._quotes,
    ..._operators,
    ..._separators,
  };

  int _skipHexDigits(int pos) {
    while (pos < _chars.length && _hexDigits.contains(this[pos])) {
      pos++;
    }
    return pos;
  }

  int _skipDigits(int pos) {
    while (pos < _chars.length && _digits.contains(this[pos])) {
      pos++;
    }
    return pos;
  }

  int _skipNumber(int pos) {
    var p = pos;
    if (this[p] == '0' && _hexMarks.contains(this[p + 1])) {
      if (!_hexDigits.contains(this[p + 2])) {
        throw InvalidTokenException('Malformed hexadecimal number (pos=$pos).');
      }
      p = _skipHexDigits(p + 3);
    } else {
      p = _skipDigits(p);
      if (this[p] == '.') {
        var idx = _skipDigits(p + 1);
        if (idx == p + 1) {
          // end of number
          return p;
        }
        p = idx;
      }
      if (_expMarks.contains(this[p])) {
        var start = p + (_signs.contains(this[p + 1]) ? 2 : 1);
        var idx = _skipDigits(start);
        if (idx == start) {
          throw InvalidTokenException('Malformed exponent (pos=$pos).');
        }
        p = idx;
      }
    }
    return p;
  }

  int _skipString(int pos) {
    var quote = this[pos];
    var p = pos + 1;
    while (p < _chars.length) {
      var ch = this[p];
      if (ch == '\\') {
        p += 2;
      } else if (ch == quote) {
        p++;
        // end of string
        return p;
      } else {
        p++;
      }
    }
    throw InvalidTokenException('Malformed string (pos=$pos).');
  }

  int _skipOperator(int pos) {
    if (this[pos] == '<' && this[pos + 1] == '=') return pos + 2;
    if (this[pos] == '>' && this[pos + 1] == '=') return pos + 2;
    if (this[pos] == '!' && this[pos + 1] == '=') return pos + 2;
    if (this[pos] == '?' && this[pos + 1] == '?') return pos + 2;
    if (this[pos] == '<' && this[pos + 1] == '<') return pos + 2;
    if (this[pos] == '>' && this[pos + 1] == '>') {
      return pos + (this[pos + 2] == '>' ? 3 : 2);
    }
    return pos + 1;
  }

  int _skipIdentifier(int pos) {
    var p = pos;
    while (p < _chars.length) {
      var ch = this[p];
      if (_delimitors.contains(ch)) {
        // end of identifier
        return p;
      }
      p++;
    }
    return p;
  }

  Iterable<Token> getTokens([Map<String, dynamic>? parameters]) sync* {
    var pos = 0;
    var len = _chars.length;
    while (pos < len) {
      final ch = this[pos];
      if (_whitespaces.contains(ch)) {
        // skip whitespaces
        pos++;
      } else if (_digits.contains(ch)) {
        // number literal
        var idx = _skipNumber(pos);
        yield Token(_chars.sublist(pos, idx).join(), Token.number);
        pos = idx;
      } else if (_quotes.contains(ch)) {
        // string literal
        var idx = _skipString(pos);
        yield Token(_chars.sublist(pos, idx).join(), Token.string);
        pos = idx;
      } else if (_operators.contains(ch)) {
        // operator
        var idx = _skipOperator(pos);
        yield Token(_chars.sublist(pos, idx).join(), Token.operator);
        pos = idx;
      } else if (_separators.contains(ch)) {
        // separator
        yield Token(_chars[pos], Token.separator);
        pos++;
      } else {
        // identifier
        var idx = _skipIdentifier(pos);
        final identifier = _chars.sublist(pos, idx).join();
        if (parameters != null &&
            identifier.startsWith('@') &&
            parameters.containsKey(identifier)) {
          yield Token(jsonEncode(parameters[identifier]), Token.parameterValue);
        } else {
          yield Token(identifier, Token.identifier);
        }
        pos = idx;
      }
    }
  }
}
