import '_mime_type.dart';

abstract class HttpHeader {
  static const contentType = 'content-type';
  static const contentLength = 'content-length';
  static const authorization = 'authorization';
  static const ifMatch = 'if-match';
  static const ifNoneMatch = 'if-none-match';
  static const userAgent = 'user-agent';

  static const msVersion = 'x-ms-version';
  static const msDate = 'x-ms-date';
  static const msOfferThroughput = 'x-ms-offer-throughput';
  static const msCosmosOfferAutopilotSettings =
      'x-ms-cosmos-offer-autopilot-settings';
  static const msRetryAfterMs = 'x-ms-retry-after-ms';
  static const msContinuation = 'x-ms-continuation';
  static const msMaxItemCount = 'x-ms-max-item-count';
  static const msAllowTentativeWrites = 'x-ms-cosmos-allow-tentative-writes';
  static const msDocumentDbExpirySeconds = 'x-ms-documentdb-expiry-seconds';
  static const msDocumentDbIsUpsert = 'x-ms-documentdb-is-upsert';
  static const msDocumentDbIsQuery = 'x-ms-documentdb-isquery';
  static const msDocumentDbPartitionKey = 'x-ms-documentdb-partitionkey';
  static const msDocumentDbPartitionKeyRangeId =
      'x-ms-documentdb-partitionkeyrangeid';
  static const msDocumentDbQueryEnableCrossPartition =
      'x-ms-documentdb-query-enablecrosspartition';
  static const msCosmosIsBatchRequest = 'x-ms-cosmos-is-batch-request';
  static const msCosmosBatchAtomic = 'x-ms-cosmos-batch-atomic';
  static const msCosmosBatchContinueOnError =
      'x-ms-cosmos-batch-continue-on-error';

  static const allowTentativeWrites = {
    msAllowTentativeWrites: 'true',
  };
  static const isUpsert = {
    msDocumentDbIsUpsert: 'true',
  };
  static const jsonPayload = {
    contentType: MimeType.json,
  };
  static const patchPayload = {
    contentType: MimeType.jsonPatch,
  };
  static const queryPayload = {
    contentType: MimeType.jsonQuery,
    msDocumentDbIsQuery: 'true',
  };
  static const enableCrossPartition = {
    msDocumentDbQueryEnableCrossPartition: 'true'
  };
}
