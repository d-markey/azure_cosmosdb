import '_mime_type.dart';

abstract class HttpHeader {
  static const contentType = 'content-type';
  static const authorization = 'authorization';
  static const msDate = 'x-ms-date';
  static const msContinuation = 'x-ms-continuation';
  static const msMaxItemCount = 'x-ms-max-item-count';
  static const msAllowTentativeWrites = 'x-ms-cosmos-allow-tentative-writes';
  static const msDocumentDbIsQuery = 'x-ms-documentdb-isquery';
  static const msVersion = 'x-ms-version';

  static const allowTentativeWrites = {msAllowTentativeWrites: 'true'};
  static const jsonPayload = {contentType: MimeType.json};
  static const apiVersion = {msVersion: '2018-12-31'};
  static const patchPayload = {contentType: MimeType.jsonPatch};
  static const queryPayload = {
    contentType: MimeType.jsonQuery,
    msDocumentDbIsQuery: 'true',
  };
}
