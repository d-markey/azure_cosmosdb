import '../_internal/_http_header.dart';

class TriggerOption {
  TriggerOption(
      {this.preInclude, this.preExclude, this.postInclude, this.postExclude});

  final List<String>? preInclude;
  final List<String>? preExclude;
  final List<String>? postInclude;
  final List<String>? postExclude;
}

extension TriggerOptionExt on Map<String, String>? {
  Map<String, String>? addTriggerOptions(TriggerOption? options) {
    final self = this;
    if (options == null) return self;
    Map<String, String>? headers;

    void add(String header, List<String>? triggers) {
      if (triggers != null && triggers.isNotEmpty) {
        headers ??= (self == null) ? {} : {...self};
        headers![header] = triggers.join(',');
      }
    }

    add(HttpHeader.msDocumentPreTriggerInclude, options.preInclude);
    add(HttpHeader.msDocumentPreTriggerExclude, options.preExclude);
    add(HttpHeader.msDocumentPostTriggerInclude, options.postInclude);
    add(HttpHeader.msDocumentPostTriggerExclude, options.postExclude);

    return headers ?? self;
  }
}
