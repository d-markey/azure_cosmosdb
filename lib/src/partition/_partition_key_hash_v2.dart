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
  static const _infinity = 0xFF;
}

class PartitionKeyHashV2 implements Comparable<PartitionKeyHashV2> {
  static const maxStringLength = 2 * 1024;
  static final PartitionKeyHashV2 _true =
      _hash(PartitionKeyComponentType._true);
  static final PartitionKeyHashV2 _false =
      _hash(PartitionKeyComponentType._false);
  static final PartitionKeyHashV2 _null =
      _hash(PartitionKeyComponentType._null);
  static final PartitionKeyHashV2 _undefined =
      _hash(PartitionKeyComponentType._undefined);
  static final PartitionKeyHashV2 _emptyString =
      _hash(PartitionKeyComponentType._string);

  PartitionKeyHashV2._(this.value);

  final BigInt value;

  factory PartitionKeyHashV2.bool(bool value) => value ? _true : _false;

  factory PartitionKeyHashV2.double(double value) {
    final dl = Float64List.fromList([value]);
    var bytes = dl.buffer.asUint8List();
    if (Endian.host == Endian.big) {
      bytes = Uint8List.fromList(bytes.reversed.toList());
    }
    return _hash([PartitionKeyComponentType._number, bytes]);
  }

  factory PartitionKeyHashV2.string(String value) {
    if (value.length > maxStringLength) {
      throw PartitionKeyException('String value is too long');
    } else if (value.isEmpty) {
      return _emptyString;
    } else {
      return _hash([PartitionKeyComponentType._string, value]);
    }
  }

  factory PartitionKeyHashV2.nullPK() => PartitionKeyHashV2._null;

  factory PartitionKeyHashV2.undefined() => PartitionKeyHashV2._undefined;

  static PartitionKeyHashV2 _hash(dynamic data) {
    BigInt hash = murmur3f(data, seed: 0) as BigInt;
    return PartitionKeyHashV2._(hash);
  }

  @override
  int compareTo(PartitionKeyHashV2 other) => value.compareTo(other.value);

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(dynamic other) => compareTo(other) == 0;

  bool operator <(dynamic other) => compareTo(other) < 0;
  bool operator <=(dynamic other) => compareTo(other) <= 0;
  bool operator >(dynamic other) => compareTo(other) > 0;
  bool operator >=(dynamic other) => compareTo(other) >= 0;
}
