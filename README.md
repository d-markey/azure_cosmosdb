[![Pub Package](https://badgen.net/pub/v/azure_cosmosdb)](https://pub.dev/packages/azure_cosmosdb)
[![Dart Platforms](https://badgen.net/pub/dart-platform/azure_cosmosdb)](https://pub.dev/packages/azure_cosmosdb)
[![Flutter Platforms](https://badgen.net/pub/flutter-platform/azure_cosmosdb)](https://pub.dev/packages/azure_cosmosdb)

[![License](https://badgen.net/pub/license/azure_cosmosdb)](https://github.com/d-markey/azure_cosmosdb/blob/master/LICENSE)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![Dart Style](https://img.shields.io/badge/style-lints-40c4ff)](https://pub.dev/packages/lints)
[![Pub Points](https://badgen.net/pub/points/azure_cosmosdb)](https://pub.dev/packages/azure_cosmosdb/score)
[![Likes](https://badgen.net/pub/likes/azure_cosmosdb)](https://pub.dev/packages/azure_cosmosdb/score)
[![Popularity](https://badgen.net/pub/popularity/azure_cosmosdb)](https://pub.dev/packages/azure_cosmosdb/score)

[![Last Commit](https://img.shields.io/github/last-commit/d-markey/azure_cosmosdb?logo=git&logoColor=white)](https://github.com/d-markey/azure_cosmosdb/commits)
[![Dart Workflow](https://github.com/d-markey/azure_cosmosdb/actions/workflows/dart.yml/badge.svg?logo=dart)](https://github.com/d-markey/azure_cosmosdb/actions/workflows/dart.yml)
[![Code Lines](https://img.shields.io/badge/dynamic/json?color=blue&label=code%20lines&query=%24.linesValid&url=https%3A%2F%2Fraw.githubusercontent.com%2Fd-markey%2Fazure_cosmosdb%2Fmain%2Fcoverage.json)](https://github.com/d-markey/azure_cosmosdb/tree/main/coverage/html)
[![Code Coverage](https://img.shields.io/badge/dynamic/json?color=blue&label=code%20coverage&query=%24.lineRate&suffix=%25&url=https%3A%2F%2Fraw.githubusercontent.com%2Fd-markey%2Fazure_cosmosdb%2Fmain%2Fcoverage.json)](https://github.com/d-markey/azure_cosmosdb/tree/main/coverage/html)

Dart API for Cosmos DB SQL.

## Summary

* [Features](#features)
* [Getting Started](#started)

## <a name="features"></a>Features

`Worker`: a base worker class managing a platform thread (Isolate or Web Worker) and the communication between
clients and  workers.

`WorkerPool<W>`: a worker pool for `W` workers. The number of workers is configurable as well as the degree of
concurrent workloads distributed to workers in the pool. Tasks posted to the worker pool can be cancelled.

## <a name="started"></a>Getting Started

Import `azure_cosmosdb` from your `pubspec.yaml` file:

```yaml
dependencies:
   azure_cosmosdb: ^0.9.0
```

## <a name="usage"></a>Usage

