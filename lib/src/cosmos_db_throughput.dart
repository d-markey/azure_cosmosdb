import 'dart:convert';

import '_internal/_http_header.dart';

import 'cosmos_db_exceptions.dart';

/// Class representing a CosmosDB throughput
class CosmosDbThroughput {
  CosmosDbThroughput(int throughput)
      : header = {
          HttpHeader.msOfferThroughput: throughput.toString(),
        } {
    if (throughput < _min) {
      throw ApplicationException(
          'Invalid throughput: minimum value is $_min RUs.');
    }
    if (throughput % 100 != 0) {
      throw ApplicationException(
          'Invalid throughput: value must be a multiple of 100 RUs.');
    }
  }

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

  static final minimum = CosmosDbThroughput(400);

  final Map<String, String> header;

  static final _min = 400;
  static final _minAutoScale = 1000;
}
