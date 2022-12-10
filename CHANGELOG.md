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
