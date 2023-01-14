import 'dart:convert';

import 'package:azure_cosmosdb/azure_cosmosdb.dart';
import 'package:azure_cosmosdb/src/partition/_partition_key_hash_v2.dart';
import 'package:murmur3/murmur3.dart';
import 'package:test/test.dart';

void main() async {
  run();
}

void run() {
  test('Equality - bool', () {
    for (var b1 in [true, false]) {
      for (var b2 in [true, false]) {
        final pk1 = PartitionKey(b1);
        final pk2 = PartitionKey(b2);
        expect(pk1 == pk2, equals(b1 == b2));
      }
    }
  });

  test('Equality - num', () {
    for (var n1 in <int>[0, 1, 2, 7, -2]) {
      for (var n2 in <double>[0.0, 1.0, 2.0, 3.5, 7.0, -2.0, -2.5]) {
        final pk1 = PartitionKey(n1);
        final pk2 = PartitionKey(n2);
        expect(pk1 == pk2, equals(n1.compareTo(n2) == 0));
      }
    }

    for (var n1 in <num>[0, 1, 2, 7, -2, 3.5, -2.5]) {
      for (var n2 in <double>[0.0, 1.0, 2.0, 3.5, 7.0, -2.0, -2.5]) {
        final pk1 = PartitionKey(n1);
        final pk2 = PartitionKey(n2);
        expect(pk1 == pk2, equals(n1.compareTo(n2) == 0));
      }
    }
  });

  test('Equality - String', () {
    for (var s1 in ['', 'aa', 'abcd', 'avec caractères spéciaux']) {
      for (var s2 in ['', 'aa', 'abcd', 'avec caractères spéciaux']) {
        final pk1 = PartitionKey(s1);
        final pk2 = PartitionKey(s2);
        expect(pk1 == pk2, equals(s1 == s2));
      }
    }
  });

  test('Equality - List', () {
    var pk1 = PartitionKey([]);
    var pk2 = PartitionKey([]);
    expect(pk1.values == pk2.values, isFalse);
    expect(pk1 == pk2, isTrue);

    pk1 = PartitionKey(['abc', 'def']);
    pk2 = PartitionKey(['abc', 'def']);
    expect(pk1.values == pk2.values, isFalse);
    expect(pk1 == pk2, isTrue);

    pk1 = PartitionKey([true, true]);
    pk2 = PartitionKey([true, true]);
    expect(pk1.values == pk2.values, isFalse);
    expect(pk1 == pk2, isTrue);

    pk1 = PartitionKey(<num>[-1, 2.5]);
    pk2 = PartitionKey(<double>[-1.0, 2.5]);
    expect(pk1.values == pk2.values, isFalse);
    expect(pk1 == pk2, isTrue);

    pk1 = PartitionKey(['abc', true, 'def']);
    pk2 = PartitionKey(['abc', true, 'def']);
    expect(pk1.values == pk2.values, isFalse);
    expect(pk1 == pk2, isTrue);

    pk1 = PartitionKey([]);
    pk2 = PartitionKey([null]);
    expect(pk1 == pk2, isFalse);

    pk1 = PartitionKey(['abc', 'def']);
    pk2 = PartitionKey(['def', 'abc']);
    expect(pk1 == pk2, isFalse);

    pk1 = PartitionKey(['abc', 'def']);
    pk2 = PartitionKey(['abc', 'def', 'abc']);
    expect(pk1 == pk2, isFalse);
  });

  test('Equality - other objects', () {
    final obj1 = Object();
    final obj2 = {};
    for (var o1 in [1, 2.5, true, "abcd", obj1, obj2, {}, Object()]) {
      for (var o2 in [obj1, obj2, {}, Object()]) {
        final pk1 = PartitionKey(o1);
        final pk2 = PartitionKey(o2);
        expect(pk1 == pk2, isFalse);
      }
    }
  });

  group('SPEC', () {
    test('Simple PK', () {
      final pk = PartitionKeySpec('/id');
      expect(pk.kind, equals('Hash'));
      expect(pk.version, equals(2));
      expect(pk.paths, equals(['/id']));
    });

    test('Simple PK - equality', () {
      var pk = PartitionKeySpec('/id');
      expect(pk, equals(pk));
      expect(pk, equals(PartitionKeySpec.id));
      expect(pk, equals(PartitionKeySpec('/id')));
      expect(pk, isNot(equals(PartitionKeySpec('/a'))));
      expect(pk, isNot(equals(PartitionKeySpec.multi(['/id']))));
    });

    test('Multi PK', () {
      final pk = PartitionKeySpec.multi(['/tenant', '/user']);
      expect(pk.kind, equals('MultiHash'));
      expect(pk.version, equals(2));
      expect(pk.paths, equals(['/tenant', '/user']));
    });

    test('Multi PK - equality', () {
      final pk = PartitionKeySpec.multi(['/a', '/b']);
      expect(pk, equals(pk));
      expect(pk, equals(PartitionKeySpec.multi(['/a', '/b'])));
      expect(pk, isNot(equals(PartitionKeySpec('/a'))));
      expect(pk, isNot(equals(PartitionKeySpec('/b'))));
      expect(pk, isNot(equals(PartitionKeySpec.multi(['/a']))));
      expect(pk, isNot(equals(PartitionKeySpec.multi(['/b']))));
      expect(pk, isNot(equals(PartitionKeySpec.multi(['/b', '/a']))));
      expect(pk, isNot(equals(PartitionKeySpec.multi(['/a', '/b', '/c']))));
      expect(pk, isNot(equals(PartitionKeySpec.multi(['/a', '/c', '/b']))));
    });
  });

  group('MURMUR3', () {
    // cf. https://github.com/Azure/azure-cosmos-dotnet-v3/blob/master/Microsoft.Azure.Cosmos/tests/Microsoft.Azure.Cosmos.Tests/Routing/MurmurHash3Test.cs

    test('double', () {
      // skip(1): the first byte is the PartitionKeyComponentType
      final bytes = PartitionKeyHashV2.getBytes(374.0).skip(1);
      final hash32 = murmur3a(bytes);
      expect(hash32, equals(3717946798));
    });

    test('string', () {
      final bytes = PartitionKeyHashV2.getBytes('afdgdd').toList();
      // skip(1): the first byte is the PartitionKeyComponentType
      // take(bytes.length - 2): the last byte is 0xFF for strings
      final hash32 = murmur3a(bytes.skip(1).take(bytes.length - 2));
      expect(hash32, equals(1099701186));
    });
  });

  group('HASH V2', () {
    // cf. https://github.com/Azure/azure-cosmosdb-java/blob/e636aa509675ea059b1c565909d8f17d8641057d/direct-impl/src/test/java/com/microsoft/azure/cosmosdb/PartitionKeyHashingTests.java

    final testCases = {
      '': '32E9366E637A71B4E710384B2F4970A0',
      'partitionKey': '013AEFCF77FA271571CF665A58C933F1',
      'a' * 1024: '332BDF5512AE49615F32C7D98C2DB86C',
      null: '378867E4430E67857ACE5C908374FE16',
      true: '0E711127C5B5A8E4726AC6DD306A3E59',
      false: '2FE1BE91E90A3439635E0E9E37361EF2',
      -128: '01DAEDABF913540367FE219B2AD06148',
      127: '0C507ACAC853ECA7977BF4CEFB562A25',
      -2147483648: '0B1660D5233C3171725B30D4A5F4CC1F',
      2147483647: '2D9349D64712AEB5EB1406E2F0BE2725',
      double.minPositive: '0E6CBA63A280927DE485DEF865800139',
      double.maxFinite: '31424D996457102634591FF245DBCC4D',
    };

    test('Test cases (all platforms)', () {
      for (var test in testCases.entries) {
        final pk = PartitionKey(test.key);
        final pkHash = PartitionKeyHashV2.multi(pk.values);
        expect(pkHash.hex, equals(test.value));
        if (test.key == null) {
          expect(pkHash, equals(PartitionKeyHashV2.nullKey()));
        } else if (test.key is String && (test.key as String).isEmpty) {
          expect(pkHash, equals(PartitionKeyHashV2.emptyStringKey()));
        } else if (test.key is bool) {
          var b = test.key as bool;
          expect(pkHash, equals(PartitionKeyHashV2.bool(b)));
          expect(
              pkHash,
              equals(b
                  ? PartitionKeyHashV2.trueKey()
                  : PartitionKeyHashV2.falseKey()));
        }
      }
    });

    final vmTestCases = {
      BigInt.parse('-9223372036854775808'): '23D5C6395512BDFEAFADAD15328AD2BB',
      BigInt.parse('9223372036854775807'): '2EDB959178DFCCA18983F89384D1629B',
    };

    test('Test cases (VM only)', () {
      for (var test in vmTestCases.entries) {
        final pk = PartitionKey(test.key.toInt());
        final hash = PartitionKeyHashV2.multi(pk.values);
        expect(hash.hex, equals(test.value));
      }
    }, testOn: '!browser');
  });

  group('RANGE', () {
    final testCases = {
      '': '32E9366E637A71B4E710384B2F4970A0',
      'partitionKey': '013AEFCF77FA271571CF665A58C933F1',
      'a' * 1024: '332BDF5512AE49615F32C7D98C2DB86C',
      null: '378867E4430E67857ACE5C908374FE16',
      true: '0E711127C5B5A8E4726AC6DD306A3E59',
      false: '2FE1BE91E90A3439635E0E9E37361EF2',
      -128: '01DAEDABF913540367FE219B2AD06148',
      127: '0C507ACAC853ECA7977BF4CEFB562A25',
      -2147483648: '0B1660D5233C3171725B30D4A5F4CC1F',
      2147483647: '2D9349D64712AEB5EB1406E2F0BE2725',
      double.minPositive: '0E6CBA63A280927DE485DEF865800139',
      double.maxFinite: '31424D996457102634591FF245DBCC4D',
    };

    test('', () {
      List<PartitionKeyRange> ranges = jsonDecode('''[
          {"id":"0","minInclusive":"","maxExclusive":"0FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"},
          {"id":"1","minInclusive":"0FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF","maxExclusive":"1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE"}, 
          {"id":"2","minInclusive":"1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE","maxExclusive":"2FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFD"}, 
          {"id":"3","minInclusive":"2FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFD","maxExclusive":"FF"}
      ]''')
          .map((r) => PartitionKeyRange.fromJson(r))
          .cast<PartitionKeyRange>()
          .toList();

      for (var test in testCases.entries) {
        final pk = PartitionKey(test.key);
        final range = ranges.findRangeFor(pk);
        expect(range, isNotNull);

        final hash = PartitionKeyHashV2.multi(pk.values);
        expect(range!.minInclusive.compareTo(hash.hex), lessThanOrEqualTo(0));
        expect(range.maxExclusive.compareTo(hash.hex), greaterThan(0));
      }
    });
  });
}
