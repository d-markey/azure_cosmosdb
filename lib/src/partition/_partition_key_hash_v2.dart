import 'dart:convert';
import 'dart:typed_data';

import 'package:murmur3/murmur3.dart';

import '../cosmos_db_exceptions.dart';

class PartitionKeyComponentType {
  static const _undefined = 0x00;
  static const _null = 0x01;
  static const _false = 0x02;
  static const _true = 0x03;
  // ignore: unused_field
  static const _minNumber = 0x04;
  static const _number = 0x05;
  // ignore: unused_field
  static const _maxNumber = 0x06;
  // ignore: unused_field
  static const _minString = 0x07;
  static const _string = 0x08;
  // ignore: unused_field
  static const _maxString = 0x09;
  // ignore: unused_field
  static const _int64 = 0x0A;
  // ignore: unused_field
  static const _int32 = 0x0B;
  // ignore: unused_field
  static const _int16 = 0x0C;
  // ignore: unused_field
  static const _int8 = 0x0D;
  // ignore: unused_field
  static const _uint64 = 0x0E;
  // ignore: unused_field
  static const _uint32 = 0x0F;
  // ignore: unused_field
  static const _uint16 = 0x10;
  // ignore: unused_field
  static const _uint8 = 0x11;
  // ignore: unused_field
  static const _binary = 0x12;
  // ignore: unused_field
  static const _guid = 0x13;
  // ignore: unused_field
  static const _float = 0x14;
  static const _infinity = 0xFF;
}

class PartitionKeyHashV2 implements Comparable<PartitionKeyHashV2> {
  static final _mask = BigInt.parse('0x3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');

  static const maxStringLength = 2 * 1024;

  static final PartitionKeyHashV2 _true =
      _hash(PartitionKeyComponentType._true);
  static final PartitionKeyHashV2 _false =
      _hash(PartitionKeyComponentType._false);
  static final PartitionKeyHashV2 _null =
      _hash(PartitionKeyComponentType._null);
  static final PartitionKeyHashV2 _undefined =
      _hash(PartitionKeyComponentType._undefined);
  static final PartitionKeyHashV2 _emptyString = _hash(
      [PartitionKeyComponentType._string, PartitionKeyComponentType._infinity]);

  PartitionKeyHashV2._(BigInt value)
      : hex = value.toRadixString(16).toUpperCase().padLeft(32, '0');

  final String hex;

  BigInt get value => BigInt.parse(hex, radix: 16);

  factory PartitionKeyHashV2.bool(bool value) => value ? _true : _false;

  factory PartitionKeyHashV2.double(num value) =>
      PartitionKeyHashV2.multi([value]);

  factory PartitionKeyHashV2.string(String value) => value.isEmpty
      ? _emptyString
      : (value.length <= maxStringLength)
          ? PartitionKeyHashV2.multi([value])
          : throw PartitionKeyException('Partition key value is too long.');

  factory PartitionKeyHashV2.nullKey() => PartitionKeyHashV2._null;

  factory PartitionKeyHashV2.trueKey() => PartitionKeyHashV2._true;

  factory PartitionKeyHashV2.falseKey() => PartitionKeyHashV2._false;

  factory PartitionKeyHashV2.emptyStringKey() =>
      PartitionKeyHashV2._emptyString;

  factory PartitionKeyHashV2.undefinedKey() => PartitionKeyHashV2._undefined;

  factory PartitionKeyHashV2.multi(List<dynamic> data) {
    final bytes = getBytes(data).toList();
    return _hash(bytes);
  }

  static Iterable<int> getBytes(dynamic value) sync* {
    if (value == null) {
      yield PartitionKeyComponentType._null;
    } else if (value is bool) {
      yield value
          ? PartitionKeyComponentType._true
          : PartitionKeyComponentType._false;
    } else if (value is num) {
      final dl = Float64List.fromList([value.toDouble()]);
      var bytes = dl.buffer.asUint8List();
      if (Endian.host == Endian.big) {
        bytes = Uint8List.fromList(bytes.reversed.toList());
      }
      yield PartitionKeyComponentType._number;
      yield* bytes;
    } else if (value is String) {
      yield PartitionKeyComponentType._string;
      yield* utf8.encode(value);
      yield PartitionKeyComponentType._infinity;
    } else if (value is Iterable) {
      for (var item in value) {
        yield* getBytes(item);
      }
    } else {
      yield PartitionKeyComponentType._undefined;
    }
  }

  static PartitionKeyHashV2 _hash(dynamic data) {
    var hash = murmur3f(data, seed: 0) as BigInt;
    // hi/lo parts are inverted in Cosmos DB
    final hex = hash.toRadixString(16).padLeft(32, '0');
    final hi = hex.substring(0, 16);
    final lo = hex.substring(16, 32);
    hash = BigInt.parse(lo + hi, radix: 16) & _mask;
    return PartitionKeyHashV2._(hash);
  }

  @override
  int compareTo(PartitionKeyHashV2 other) => value.compareTo(other.value);

  @override
  int get hashCode => hex.hashCode;

  @override
  bool operator ==(dynamic other) => compareTo(other) == 0;
}
