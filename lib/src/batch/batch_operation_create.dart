import '../base_document.dart';
import '../partition/partition_key_spec.dart';
import 'batch_operation.dart';

class BatchOperationCreate<T extends BaseDocument>
    extends BatchOperationOnItem<T> {
  BatchOperationCreate(T item, {PartitionKeySpec? pk}) : super(item, pk: pk);

  @override
  final BatchOperationType op = BatchOperationType.create;

  @override
  Map<String, dynamic> toJson() => super.toJson();
}
