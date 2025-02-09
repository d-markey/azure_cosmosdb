import '../_internal/_extensions.dart';
import '../access_control/cosmos_db_access_control.dart';
import '../base_document.dart';
import '../client/_context.dart';
import '../cosmos_db_container.dart';
import 'cosmos_db_function.dart';
import 'cosmos_db_script.dart';
import 'cosmos_db_sproc.dart';
import 'cosmos_db_trigger.dart';
import 'cosmos_db_trigger_operation.dart';
import 'cosmos_db_trigger_type.dart';

part 'cosmos_db_functions.dart';
part 'cosmos_db_sprocs.dart';
part 'cosmos_db_triggers.dart';

/// Class used to manage [CosmosDbSproc]s and [CosmosDbTrigger]s in a [CosmosDbContainer].
abstract class _CosmosDbScripts<T extends CosmosDbScript> {
  _CosmosDbScripts(this.container, this.artifactId, this._fromJson)
      : url = '${container.url}/$artifactId';

  /// The [CosmosDbContainer] this script belongs to.
  final CosmosDbContainer container;

  /// The [url] for the code artifacts.
  final String url;

  /// The resource id (sprocs or triggers)
  final String artifactId;

  String get _resultSet;

  final T Function(JSonMessage) _fromJson;

  Future<T> create(T artifact, {CosmosDbAccessControl? accessControl}) =>
      container.client.post<T>(
        url,
        artifact,
        Context(
          type: artifactId,
          resId: container.url,
          accessControl: accessControl,
          builder: _fromJson,
        ),
      );

  Future<Iterable<T>> list({CosmosDbAccessControl? accessControl}) =>
      container.client.getMany<T>(
        url,
        _resultSet,
        Context(
          type: artifactId,
          resId: container.url,
          accessControl: accessControl,
          builder: _fromJson,
        ),
      );

  Future<T> update(T artifact, {CosmosDbAccessControl? accessControl}) {
    final artifactUrl = buildUrl(url, artifact.id);
    return container.client.put<T>(
      artifactUrl,
      artifact,
      Context(
        type: artifactId,
        resId: artifactUrl,
        accessControl: accessControl,
        builder: _fromJson,
      ),
    );
  }

  Future<void> delete(T artifact, {CosmosDbAccessControl? accessControl}) {
    final artifactUrl = buildUrl(url, artifact.id);
    return container.client.delete(
      artifactUrl,
      Context(
        type: artifactId,
        resId: artifactUrl,
        accessControl: accessControl,
        builder: _fromJson,
      ),
    );
  }
}
