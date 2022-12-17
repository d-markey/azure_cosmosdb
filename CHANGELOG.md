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
