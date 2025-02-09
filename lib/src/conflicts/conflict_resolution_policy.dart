import '../base_document.dart';
import 'conflict_resolution_policy_mode.dart';

class ConflictResolutionPolicy {
  ConflictResolutionPolicy._(
    this.mode,
    this.conflictResolutionPath,
    this.conflictResolutionProcedure,
  );

  ConflictResolutionPolicy.lastWriterWins({
    String? conflictResolutionPath,
  }) : this._(
          ConflictResolutionPolicyMode.lastWriterWins,
          conflictResolutionPath ?? '/_ts',
          null,
        );

  ConflictResolutionPolicy.custom(
    String conflictResolutionProcedure,
  ) : this._(
          ConflictResolutionPolicyMode.custom,
          null,
          conflictResolutionProcedure,
        );

  final ConflictResolutionPolicyMode mode;
  final String? conflictResolutionPath;
  final String? conflictResolutionProcedure;

  /// Serializes this instance to a JSON object.
  JSonMessage toJson() => {
        'mode': mode.name,
        'conflictResolutionPath': conflictResolutionPath ?? '',
        'conflictResolutionProcedure': conflictResolutionProcedure ?? '',
      };

  static ConflictResolutionPolicy? fromJson(Map? json) => (json == null)
      ? null
      : ConflictResolutionPolicy._(
          ConflictResolutionPolicyMode.tryParse(json['mode'])!,
          json['conflictResolutionPath'],
          json['conflictResolutionProcedure'],
        );
}
