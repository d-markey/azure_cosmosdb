const currentApiVersion = '2018-12-31';
const previewApiVersion = '2020-07-15';

/// Class representing the features supported by a Cosmos DB client.
class Features {
  const Features._(this.version, {required this.multiHash});

  final String version;
  final bool multiHash;

  static const _default = Features._('', multiHash: false);

  /// Features for the current version (see [currentApiVersion]).
  static const current = Features._(currentApiVersion, multiHash: false);

  /// Features for the preview version (see [previewApiVersion]).
  static const preview = Features._(previewApiVersion, multiHash: true);

  static const _features = [_default, current, preview];

  /// Returns the features for the specified [version].
  static Features getFeatures(String version) =>
      _features.firstWhere((f) => f.version == version, orElse: () => _default);
}
