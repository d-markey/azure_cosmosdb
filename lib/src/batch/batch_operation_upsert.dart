import '../base_document.dart';
import '../partition/partition_key_spec.dart';
import 'batch_operation.dart';

class BatchOperationUpsert<T extends BaseDocument>
    extends BatchOperationOnItem<T> {
  BatchOperationUpsert(T item, {PartitionKeySpec? pk}) : super(item, pk: pk);

  @override
  final BatchOperationType op = BatchOperationType.upsert;
}
