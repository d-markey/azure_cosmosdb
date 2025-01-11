import 'dart:convert';

import 'package:azure_cosmosdb/src/cosmos_db_exceptions.dart';
import 'package:azure_cosmosdb/src/patch/_token.dart';
import 'package:azure_cosmosdb/src/patch/_tokenizer.dart';
import 'package:test/test.dart';

void main() {
  run();
}

void run() {
  test('Numbers - integer', () {
    _checkExpr('1234', null, ['1234']);

    _checkExpr('+1234', null, ['+', '1234']);
    _checkExpr('-1234', null, ['-', '1234']);
  });

  test('Numbers - hexadecimal', () {
    _checkExpr('0x1234', null, ['0x1234']);
    _checkExpr('0x12AB', null, ['0x12AB']);
    _checkExpr('0xab56', null, ['0xab56']);

    _checkExpr('+0x1234', null, ['+', '0x1234']);
    _checkExpr('-0x12AB', null, ['-', '0x12AB']);
    _checkExpr('-0xab56', null, ['-', '0xab56']);
  });

  test('Numbers - decimal', () {
    _checkExpr('0.1234', null, ['0.1234']);
    _checkExpr('123.45', null, ['123.45']);

    _checkExpr('123e4', null, ['123e4']);
    _checkExpr('12.3e-45', null, ['12.3e-45']);
    _checkExpr('0.123e-4', null, ['0.123e-4']);
    _checkExpr('0.123e4', null, ['0.123e4']);
    _checkExpr('0.123e+4', null, ['0.123e+4']);
    _checkExpr('0.123e-4', null, ['0.123e-4']);

    _checkExpr('+0.1234', null, ['+', '0.1234']);
    _checkExpr('-0.1234', null, ['-', '0.1234']);
    _checkExpr('+0.123e-4', null, ['+', '0.123e-4']);
    _checkExpr('-0.123e-4', null, ['-', '0.123e-4']);
  });

  test('Strings', () {
    _checkExpr('\'abcd\'', null, ['\'abcd\'']);
    _checkExpr('"efgh"', null, ['"efgh"']);
    _checkExpr('"ef gh"', null, ['"ef gh"']);

    _checkExpr('\'ab\\\'cd\'', null, ['\'ab\\\'cd\'']);
    _checkExpr('"ef\'gh"', null, ['"ef\'gh"']);
    _checkExpr('"ef\\" gh"', null, ['"ef\\" gh"']);
    _checkExpr('"ef\\bgh"', null, ['"ef\\bgh"']);
    _checkExpr('"ef" "gh"', null, ['"ef"', '"gh"']);
    _checkExpr('"ef" \'gh\'', null, ['"ef"', '\'gh\'']);
  });

  test('Operators', () {
    _checkExpr('+', null, ['+']);
    _checkExpr('-', null, ['-']);
    _checkExpr('*', null, ['*']);
    _checkExpr('/', null, ['/']);
    _checkExpr('%', null, ['%']);
    _checkExpr('.', null, ['.']);
    _checkExpr('?', null, ['?']);
    _checkExpr('??', null, ['??']);
    _checkExpr('|', null, ['|']);
    _checkExpr('||', null, ['|', '|']);
    _checkExpr('&', null, ['&']);
    _checkExpr('&&', null, ['&', '&']);
    _checkExpr('^', null, ['^']);
    _checkExpr('=', null, ['=']);
    _checkExpr('!=', null, ['!=']);
    _checkExpr('<', null, ['<']);
    _checkExpr('<<', null, ['<<']);
    _checkExpr('<=', null, ['<=']);
    _checkExpr('>', null, ['>']);
    _checkExpr('>>', null, ['>>']);
    _checkExpr('>=', null, ['>=']);
    _checkExpr('>>>', null, ['>>>']);
    _checkExpr('<<<<', null, ['<<', '<<']);
    _checkExpr('++-*-', null, ['+', '+', '-', '*', '-']);
  });

  test('Separators', () {
    _checkExpr('()[]{},:', null, ['(', ')', '[', ']', '{', '}', ',', ':']);
  });

  test('Whitespaces', () {
    _checkExpr('    ', null, []);
    _checkExpr('   Ab ', null, ['Ab']);
    _checkExpr('   45 ', null, ['45']);
    _checkExpr('   "45   " ', null, ['"45   "']);
  });

  test('Identifiers', () {
    _checkExpr('SELECT', null, ['SELECT']);
    _checkExpr('SELECT DISTINCT', null, ['SELECT', 'DISTINCT']);
    _checkExpr('name', null, ['name']);
    _checkExpr('@var', null, ['@var']);
    _checkExpr('false', null, ['false']);
    _checkExpr('true', null, ['true']);
  });

  test('Arrays', () {
    _checkExpr('[1, 2, 345.2, -3+2.2*-2, 3.7e5, false]', null, [
      '[',
      '1',
      ',',
      '2',
      ',',
      '345.2',
      ',',
      '-',
      '3',
      '+',
      '2.2',
      '*',
      '-',
      '2',
      ',',
      '3.7e5',
      ',',
      'false',
      ']'
    ]);
  });

  test('Objects', () {
    _checkExpr('{"a": true, "C": -3.4, "sub": {\'a\': false}}', null, [
      '{',
      '"a"',
      ':',
      'true',
      ',',
      '"C"',
      ':',
      '-',
      '3.4',
      ',',
      '"sub"',
      ':',
      '{',
      '\'a\'',
      ':',
      'false',
      '}',
      '}'
    ]);
  });

  test('Expressions', () {
    _checkExpr('1+2=3', null, ['1', '+', '2', '=', '3']);

    _checkExpr('(1+2.4e-5-3+0xabcd)*-7.2', null, [
      '(',
      '1',
      '+',
      '2.4e-5',
      '-',
      '3',
      '+',
      '0xabcd',
      ')',
      '*',
      '-',
      '7.2'
    ]);

    _checkExpr('true ? \'always\' : \'never\'', null,
        ['true', '?', '\'always\'', ':', '\'never\'']);

    _checkExpr('x % 2 = 0 ? \'even\' : \'odd\'', null,
        ['x', '%', '2', '=', '0', '?', '\'even\'', ':', '\'odd\'']);

    _checkExpr('cos(pi)', null, ['cos', '(', 'pi', ')']);

    _checkExpr(
        'cos(acos(pi))', null, ['cos', '(', 'acos', '(', 'pi', ')', ')']);

    _checkExpr('ST_WITHIN(@EiffelTower, @Paris)', null,
        ['ST_WITHIN', '(', '@EiffelTower', ',', '@Paris', ')']);

    _checkExpr('from c where c.label = \'HELLO World!\'', null,
        ['from', 'c', 'where', 'c', '.', 'label', '=', '\'HELLO World!\'']);
  });

  test('Invalid tokens', () {
    var tokenizer = Tokenizer('0xz');
    expect(
        () => tokenizer.getTokens().toList(), throwsA(isA<ParsingException>()));
    tokenizer = Tokenizer('123e*3');
    expect(
        () => tokenizer.getTokens().toList(), throwsA(isA<ParsingException>()));
    tokenizer = Tokenizer('x = \'test');
    expect(
        () => tokenizer.getTokens().toList(), throwsA(isA<ParsingException>()));
    tokenizer = Tokenizer('x = test"');
    expect(
        () => tokenizer.getTokens().toList(), throwsA(isA<ParsingException>()));
  });

  test('Invalid syntax but valid tokens', () {
    // number identifier
    var tokens = Tokenizer('123fdr').getTokens().toList();
    expect(tokens, isA<List<Token>>());
    expect(tokens.length, equals(2));

    // number operator
    tokens = Tokenizer('123.').getTokens().toList();
    expect(tokens, isA<List<Token>>());
    expect(tokens.length, equals(2));

    // number operator operator string
    tokens = Tokenizer('123<+"test"').getTokens().toList();
    expect(tokens, isA<List<Token>>());
    expect(tokens.length, equals(4));

    // number identifier operator identifier
    tokens = Tokenizer('123@var1>>>@var2').getTokens().toList();
    expect(tokens, isA<List<Token>>());
    expect(tokens.length, equals(4));

    // identifier separator identifier separator identifier separator number separator
    tokens = Tokenizer('f(g(h(1)').getTokens().toList();
    expect(tokens, isA<List<Token>>());
    expect(tokens.length, equals(8));
  });

  test('Parameter values replace variable names', () {
    final params = {
      '@int': -3,
      '@int0': 0,
      '@int1': 1,
      '@int2': 2,
      '@int3': 3,
      '@int10': 10,
      '@double': 4.2e-3,
      '@smallDouble': 4.2e-11,
      '@bool': false,
      '@string': 'bad one',
      '@str': 'good one',
      '@array': [1, 2, 3],
      '@object': {'str': 'a', 'num': 2.4},
    };

    _checkExpr('@int', params, ['-3']);
    _checkExpr('@int0', params, ['0']);
    _checkExpr('@double', params, [jsonEncode(params['@double'])]);
    _checkExpr('@smallDouble', params, [jsonEncode(params['@smallDouble'])]);
    _checkExpr('@bool', params, ['false']);
    _checkExpr('@str', params, [jsonEncode(params['@str'])]);
    _checkExpr('@array', params, [jsonEncode(params['@array'])]);
    _checkExpr('@object', params, [jsonEncode(params['@object'])]);

    _checkExpr('@int1+@int2=@int3', params, ['1', '+', '2', '=', '3']);
  });

  test(
      'Variable names in string literals are not replaced with parameter values',
      () {
    final params = {
      '@int': -3,
      '@int0': 0,
      '@int1': 1,
      '@int2': 2,
      '@int3': 3,
      '@int10': 10,
      '@double': 4.2e-3,
      '@smallDouble': 4.2e-11,
      '@bool': false,
      '@string': 'bad one',
      '@str': 'good one',
      '@array': [1, 2, 3],
      '@object': {'str': 'a', 'num': 2.4},
    };

    _checkExpr('\'@int\'', params, ['\'@int\'']);
    _checkExpr('@string+\'@str\'', params,
        [jsonEncode(params['@string']), '+', '\'@str\'']);
  });

  test('Variable names must start with @', () {
    final params = {'SELECT': 'FORMAT', '@drive': 'C:'};

    _checkExpr('SELECT C:', params, ['SELECT', 'C', ':']);
    _checkExpr('@SELECT @drive', params, ['@SELECT', jsonEncode('C:')]);
    _checkExpr('@SELECT C:', params, ['@SELECT', 'C', ':']);
  });
}

void _checkExpr(
    String expr, Map<String, dynamic>? params, List<String> tokens) {
  final result = Tokenizer(expr).getTokens(params).map((t) => t.text).toList();
  expect(result.length, equals(tokens.length),
      reason: ' (expression = $expr, tokens = $result)');
  for (var i = 0; i < tokens.length; i++) {
    expect(result[i], equals(tokens[i]),
        reason: ' (expression = $expr, i = $i, tokens = ${result.join(' ')})');
  }
}
