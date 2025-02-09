class ConflictResolutionPolicyMode {
  const ConflictResolutionPolicyMode._(
    this.name,
  );

  final String name;

  /// Last writer wins.
  static const lastWriterWins =
      ConflictResolutionPolicyMode._('LastWriterWins');

  /// Custom policy.
  static const custom = ConflictResolutionPolicyMode._('Custom');

  static final _values = {
    lastWriterWins.name: lastWriterWins,
    custom.name: custom
  };

  /// Returns the [IndexingMode] constant corresponding to the specified [mode].
  static ConflictResolutionPolicyMode? tryParse(String? mode) => _values[mode];
}
