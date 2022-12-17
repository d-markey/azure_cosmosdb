import 'dart:async';

import '_internal/_http_call.dart';
import '_internal/_http_status_codes.dart';

abstract class InternalException implements Exception {
  InternalException._(String? message) : message = message ?? '';

  final String message;

  @override
  String toString() =>
      message.isNotEmpty ? '$runtimeType: $message' : runtimeType.toString();
}

class ApplicationException extends InternalException {
  ApplicationException(String message) : super._(message);
}

class InvalidTokenException extends ApplicationException {
  InvalidTokenException(String message) : super(message);
}

abstract class ContextualizedException extends InternalException {
  ContextualizedException._(String method, this.url, String? message)
      : method = method.toUpperCase(),
        super._(message);

  ContextualizedException _withContext(String method, String url);

  final String method;
  final String url;

  bool get hasContext => method.isNotEmpty && url.isNotEmpty;

  @override
  String toString() =>
      hasContext ? '$method $url: ${super.toString()}' : super.toString();
}

/// Base [CosmosDbException] class for CosmosDB errors.
class CosmosDbException extends ContextualizedException {
  CosmosDbException._(
      String method, String url, this.statusCode, String? message)
      : super._(method, url, message ?? 'Error $statusCode');

  factory CosmosDbException._internal(String method, String url, int statusCode,
      [String? message]) {
    message ??= 'Error $statusCode';
    switch (statusCode) {
      case HttpStatusCode.notModified:
        return NotModifiedException._('', '', message);
      case HttpStatusCode.unauthorized:
        return UnauthorizedException._('', '', message);
      case HttpStatusCode.forbidden:
        return ForbiddenException._('', '', message);
      case HttpStatusCode.notFound:
        return NotFoundException._('', '', message);
      case HttpStatusCode.conflict:
        return ConflictException._('', '', message);
      case HttpStatusCode.preconditionFailure:
        return PreconditionFailureException._('', '', message);
      default:
        return CosmosDbException._('', '', statusCode, message);
    }
  }

  factory CosmosDbException(int statusCode, [String? message]) =>
      CosmosDbException._internal('', '', statusCode, message);

  @override
  CosmosDbException _withContext(String method, String url) =>
      CosmosDbException._internal(method, url, statusCode, message);

  final int statusCode;
}

class NotModifiedException extends CosmosDbException {
  NotModifiedException._(String method, String url, [String? message])
      : super._(method, url, HttpStatusCode.notModified, message);
}

class UnauthorizedException extends CosmosDbException {
  UnauthorizedException._(String method, String url, [String? message])
      : super._(method, url, HttpStatusCode.unauthorized, message);
}

class ForbiddenException extends CosmosDbException {
  ForbiddenException._(String method, String url, [String? message])
      : super._(method, url, HttpStatusCode.forbidden, message);
}

class ConflictException extends CosmosDbException {
  ConflictException._(String method, String url, [String? message])
      : super._(method, url, HttpStatusCode.conflict, message);
}

class NotFoundException extends CosmosDbException {
  NotFoundException._(String method, String url, [String? message])
      : super._(method, url, HttpStatusCode.notFound, message);
}

class PreconditionFailureException extends CosmosDbException {
  PreconditionFailureException._(String method, String url, [String? message])
      : super._(method, url, HttpStatusCode.preconditionFailure, message);
}

class UnknownDocumentTypeException extends ContextualizedException {
  UnknownDocumentTypeException._(String method, String url, this.docType)
      : super._(method, url, 'Unknown document type $docType');

  UnknownDocumentTypeException(Type docType) : this._('', '', docType);

  @override
  UnknownDocumentTypeException _withContext(String method, String url) =>
      UnknownDocumentTypeException._(method, url, docType);

  final Type docType;
}

class BadResponseException extends ContextualizedException {
  BadResponseException._(String method, String url, String message)
      : super._(method, url, message);

  BadResponseException(String message) : this._('', '', message);

  @override
  BadResponseException _withContext(String method, String url) =>
      BadResponseException._(method, url, message);
}

// internal use
extension ContextualizedExceptionExt<T> on Future<T> {
  Future<T> rethrowContextualizedException(HttpCall call) =>
      onError<ContextualizedException>((error, stackTrace) =>
          throw error._withContext(call.method.name, call.uri));
}
