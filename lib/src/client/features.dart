const currentApiVersion = '2018-12-31';
const previewApiVersion = '2020-07-15';

class Features {
  const Features(this.version, {required this.multiHash});

  final String version;
  final bool multiHash;

  static const $default = Features('', multiHash: false);
  static const current = Features(currentApiVersion, multiHash: false);
  static const preview = Features(previewApiVersion, multiHash: true);

  static const _features = [$default, current, preview];

  static Features getFeatures(String version) =>
      _features.firstWhere((f) => f.version == version, orElse: () => $default);
}
