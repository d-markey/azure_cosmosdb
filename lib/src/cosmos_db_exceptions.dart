import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';

import '_internal/_http_call.dart';
import 'base_document.dart';
import 'client/http_status_codes.dart';

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

class ParsingException extends ApplicationException {
  ParsingException(String message) : super(message);
}

class PartitionKeyException extends ApplicationException {
  PartitionKeyException(String message) : super(message);
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
        return NotModifiedException._(method, url, message);
      case HttpStatusCode.unauthorized:
        return UnauthorizedException._(method, url, message);
      case HttpStatusCode.badRequest:
        return BadRequestException._(method, url, message);
      case HttpStatusCode.forbidden:
        return ForbiddenException._(method, url, message);
      case HttpStatusCode.notFound:
        return NotFoundException._(method, url, message);
      case HttpStatusCode.conflict:
        return ConflictException._(method, url, message);
      case HttpStatusCode.preconditionFailure:
        return PreconditionFailureException._(method, url, message);
      case HttpStatusCode.invalidToken:
        return InvalidTokenException._(method, url, message);
      default:
        return CosmosDbException._(method, url, statusCode, message);
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

class InvalidTokenException extends CosmosDbException {
  InvalidTokenException._(String method, String url, [String? message])
      : super._(method, url, HttpStatusCode.invalidToken, message);
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

class BadRequestException extends CosmosDbException {
  BadRequestException._(String method, String url, String message)
      : super._(method, url, HttpStatusCode.badRequest, message);

  BadRequestException(String message) : this._('', '', message);

  @override
  BadRequestException _withContext(String method, String url) =>
      BadRequestException._(method, url, message);

  static final _errorsPattern = RegExp(r'\s*\{\s*"Errors"\s*:\s*\[\s*"');
  static final _errorPattern = RegExp(
    r'Exception\s*=\s*([^\r\n]*)[\r\n]+Stack trace:\s*(.*)',
    dotAll: true,
  );
  static final _traceDelimitor = RegExp(r'\s+at\s+');

  static String _extractJson(String str) {
    final len = str.length;
    // str starts with '{'
    var pos = 0, count = 0;
    while (pos < len) {
      var ch = str[pos++];
      switch (ch) {
        case '{':
          count++;
          break;
        case '}':
          count--;
          if (count == 0) return str.substring(0, pos);
          break;
        case '"': // JSON only allows double-quotes
          while (pos < len) {
            ch = str[pos++];
            if (ch == '"') break; // end of string --> done
            if (ch == '\\') pos++; // escaped char --> skip
          }
          break;
      }
    }
    return str;
  }

  SprocException? asSprocException() {
    final match = _errorsPattern.firstMatch(message);
    if (match == null) return null;
    try {
      final json = _extractJson(message.substring(match.start).trim());
      final jsonErrors = (jsonDecode(json) as JSonMessage)['Errors'] as List;
      final errors = <JsError>[];
      for (var err in jsonErrors) {
        final match = _errorPattern.firstMatch(err);
        if (match != null) {
          final msg = (match.group(1) ?? '').trim();
          final st = (match.group(2) ?? '').split(_traceDelimitor);
          if (st.first == msg) st.removeAt(0);
          errors.add(JsError(msg, st));
        }
      }
      return SprocException.from(this, errors);
    } catch (_) {
      return null;
    }
  }
}

class JsError {
  JsError(this.message, this.stackTrace);

  final String message;
  final List<String> stackTrace;
}

class SprocException extends BadRequestException {
  SprocException._(String method, String url, String message, this.errors)
      : super._(method, url, message);

  SprocException(List<JsError> errors) : this._('', '', '', errors);

  SprocException.from(BadRequestException ex, List<JsError> errors)
      : this._(ex.method, ex.url, ex.message, errors);

  final List<JsError> errors;
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
@internal
extension ContextualizedExceptionInternalExt<T> on Future<T> {
  Future<T> rethrowContextualizedException(HttpCall call) =>
      onError<ContextualizedException>((error, stackTrace) =>
          throw error._withContext(call.method.name, call.uri));
}
