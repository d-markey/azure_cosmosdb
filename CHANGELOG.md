## 3.0.0

- Add support for stored procedures, user-defined functions and triggers. See accessors `sprocs`, `udfs` and `triggers` in `CosmosDbContainer`. Please refer to unit tests for examples calling custom scripts.
- Add support for `conflictResolutionPolicy` on containers.
- Add support for `defaultTtl` on containers.
- Add support for `analyticalStorageTtl` on containers (experimental, untested).

## 2.3.1

- BREAKING CHANGE: reworked the access-control classes and methods. `useAuthorization()`/`usePermission()` are deprecated in favor of `grantAccess()`, and `clearAuthorization()`/`clearPermission()` in favor of `revokeAccess()`. Optional arguments `authorization` and `permission` are replaced by `accessControl`.
- Make document ids non-nullable (`Object` instead of `dynamic`).

## 2.3.0

- Rename `Authorization` to `CosmosDbAuthorization` and make it public.
- Add optional `authorization` parameter to methods already supporting `CosmosDbPermission`.
- Make `usePermission` obsolete: please use `useAuthorization` instead. A `CosmosDbAuthorization` can be built from a `CosmosDbPermission`.
- Rename `InvalidTokenException` to `ParsingException`.
- Add new `InvalidTokenException` as an HTTP exception for invalid or missing tokens.
- Reworked tests & activate Wasm tests.
- Update jGenHTML to version 1.6 (test coverage tooling).

## 2.2.2

- Fix lints warnings reported by pub.dev.
- Update tests as https://github.com/Azure/azure-cosmos-dotnet-v3/issues/3659 has been fixed.

## 2.2.1

- Add support for older containers where `PartitionKeySpec.version` is null -- fixes https://github.com/d-markey/azure_cosmosdb/issues/12.

## 2.2.0

- Add none constructor to throughput for serverless config - PR https://github.com/d-markey/azure_cosmosdb/pull/10 by https://github.com/djkingCanada - fixes https://github.com/d-markey/azure_cosmosdb/issues/7.
- Improve error message if partition key is not provided for a new container - PR https://github.com/d-markey/azure_cosmosdb/pull/9 by https://github.com/djkingCanada.

## 2.1.1

- Upgrade version of `http`.

## 2.1.0

- Enable support for Dart 3.

## 2.0.2

- Upgrade version of `murmur3`.

## 2.0.1

- Improved documentation & tests.
- Retry batch operations failing with a 429 "Too many requests" status.

## 2.0.0

- Added [PartitionKeySpec] for partition key definition. A [PartitionKeySpec] must be provided when creating a [CosmosDbContainer]. The static final instance [PartitionKeySpec.id] can be used as the default partition key `['/id']`. When opening an existing collection, the [PartitionKeySpec] is loaded from the Cosmos DB response. [PartitionKeySpec.from] extracts the partition key from a [BaseDocument] according to the partition key definition.
- Support for multiple paths in [PartitionKeySpec] is available, in which case the [CosmosDbServer] connection must be initialized with `preview: true`.
- Added [PartitionKey] for providing a partition key when operating on documents/queries. The special value [PartitionKey.all] enables cross-partition queries.
- Added [TransactionalBatch] and [CrossPartionBatch] for batch processing.
- Please note that support for batch and multi-partition key are still **experimental**.
- **Breaking changes** - several classes have been renamed e.g. [CosmosDbCollection] --> [CosmosDbContainer], APIs dealing with bare `String` partition keys now use [PartitionKey]/[PartitionKeySpec], etc. 

## 1.8.1

- `_client.dart`: return early with `null` upon a "204 - No Content" status code (fix for https://github.com/d-markey/azure_cosmosdb/issues/1). Also skip parsing the response body if `content-length` is zero.

## 1.8.0

- Added support for patching documents. A document may be patched conditionally and the condition can be parameterized (parameter values are integrated into the condition client-side, as Cosmos DB does not accept parameterized conditions out-of-the-box). Variable names MUST start with `@`.
- Added `CosmosDbCollection.get()` to retrieve the latest version of a document. When the `document` has mixin `EtagMixin`, the value of the `_etag` field is sent to Cosmos DB in the `If-None-Match` header (causing a response with HTTP status code 304 "Not modified", in which case the `document` is returned as is).
- Added optional `document` parameter for `CosmosDbCollection.delete()`. When provided, the `document` attributes takes over the `id` value. The `id` parameter is deprecated and will eventually be removed.
- Added optional `checkEtag` parameter (default value: `true`) for `CosmosDbCollection.delete()` and `CosmosDbCollection.replace()`. When the `document` has mixin `EtagMixin` and `checkEtag` is `true`, the value of the `_etag` field is sent to Cosmos DB in the `If-Match` header. If the document has been updated in the meantime, a `PreconditionFailureException` exception will be thrown because the `_etag` field's value will have changed in Cosmos DB (causing a response with HTTP status code 412 "Precondition failure").
- Added `PartitionKey` field on `CosmosDbCollection` and marked `PartitionKeys` as obsolete. Use `PartitionKey` instead.
- Added `PartitionKeyMixin` to support custom partition keys in documents.
- Added support for throttling requests when Cosmos DB replies with HTTP status code 429 "Too many requests".

## 1.6.1

- Update README.md
- Added support for throughput when creating a database or a collection.

## 1.6.0

- Renamed `Line` class to `LineString`.
- Fix various issues in GeoJSON serialization (lat/long order in the JSON-array, serialization/deserialization...).
- Added unit tests to validate the spatial data sets used in tests.
- Added unit tests for spatial queries.

## 1.5.0

- Supports bounding box in spatial indexes.
- New class `Point` to represent spatial positions.
    - 2D/3D euclidean coordinates (aka geometry).
    - Latitude/longitude/optional altitude coordinates (aka geography).
- New classes to represent shapes supported by CosmosDB: `Line`, `Polygon`, `MultiPolygon`.
- Distance calculators for both geometrical (euclidean) and geographical (latitude/longitude) shapes.
    - Comes with a geographical distance calculator preconfigured with the Earth's radius in kilometers.
- Renamed `Exception` class to `CosmosDbException` (could be a breaking change).
- Most base classes `ClassName` have also been renamed to `CosmosDbClassName`.
    - This should eliminate the need for aliasing the Cosmos DB library while avoiding name collisions in your app. E.g. names for `User`, `Collection`, ... were too generic and could cause conflict with your code or other libraries.
    - This should not be a breaking change as previous names are still available, yet deprecated. They will be removed in a future version.
- Removed `DebugHttpClient` from the mainstream `azure_cosmosdb` library (could be a breaking change).
    - The debug HTTP client can still be used by importing `azure_cosmosdb_debug` instead.
- Test cases have been updated accordingly, and enriched to cover indexing policies and geometrical/geographical shapes.

## 1.0.0

- Add support for indexing policies when creating collections.

## 0.9.3

- Re-enable Web platforms support.

## 0.9.2

- Improve description.

## 0.9.1

- Added default retry policy from package https://pub.dev/packages/retry.

## 0.9.0

- Initial release.
- Support for Server, Databases, Collections, Users and Permissions
- Document base classes: BaseDocument, BaseDocumentWithEtag
- Support for SQL query
- Unit tests & code coverage (currently limited to Server, Databases and Collections)
