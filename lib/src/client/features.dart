import '_cosmosdb_api_versions.dart';

/// Class representing the features supported by a Cosmos DB client.
class Features {
  const Features._(
    this.version, {
    required this.hierarchicalPartitioning,
    required this.analyticalStorage,
  });

  final String version;
  final bool hierarchicalPartitioning;
  final bool analyticalStorage;

  static const _default = Features._(
    '',
    hierarchicalPartitioning: false,
    analyticalStorage: false,
  );

  /// Features for the current version (see [cosmosdb_2018_12_31]).
  static const current = Features._(
    cosmosdb_2018_12_31,
    hierarchicalPartitioning: false,
    analyticalStorage: false,
  );

  /// Features for the preview version (see [cosmosdb_2020_07_15]).
  static const preview = Features._(
    cosmosdb_2020_07_15,
    hierarchicalPartitioning: true,
    analyticalStorage: true,
  );

  static const _features = [_default, current, preview];

  /// Returns the features for the specified [version].
  static Features getFeatures(String version) =>
      _features.firstWhere((f) => f.version == version, orElse: () => _default);
}
