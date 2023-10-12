import 'dart:convert';

import '_internal/_http_header.dart';

import 'cosmos_db_exceptions.dart';

/// Class representing a CosmosDB throughput.
class CosmosDbThroughput {
  /// Creates a new manual [throughput] RUs. Must be a multiple of 100. Minimum allowed
  /// is 400 RUs.
  CosmosDbThroughput(int throughput) : header = createHeader(throughput);

  /// Used for servles instances where throughput can't be set
  CosmosDbThroughput.none() : header = {};

  static Map<String, String> createHeader(int throughput) {
    if (throughput < _min) {
      throw ApplicationException(
          'Invalid throughput: minimum value is $_min RUs.');
    }
    if (throughput % 100 != 0) {
      throw ApplicationException(
          'Invalid throughput: value must be a multiple of 100 RUs.');
    }
    return {
      HttpHeader.msOfferThroughput: throughput.toString(),
    };
  }

  /// Creates a new auto-scale throughput for [maxThroughput] RUs. Must be a multiple
  /// of 1000. Minimum allowed is 1000 RUs.
  CosmosDbThroughput.autoScale(int maxThroughput)
      : header = {
          HttpHeader.msCosmosOfferAutopilotSettings:
              jsonEncode({'maxThroughput': maxThroughput}),
        } {
    if (maxThroughput < _minAutoScale) {
      throw ApplicationException(
          'Invalid max throughput: minimum value is $_minAutoScale RUs.');
    }
    if (maxThroughput % 1000 != 0) {
      throw ApplicationException(
          'Invalid max throughput: value must be a multiple of 1000 RUs.');
    }
  }

  /// Minimum manual throughput (400 RU).
  static final minimum = CosmosDbThroughput(400);

  /// The HTTP header representing the specified throughput.
  final Map<String, String> header;

  static final _min = 400;
  static final _minAutoScale = 1000;
}
