import 'dart:math';

import 'package:azure_cosmosdb/azure_cosmosdb.dart';

final _rnd = Random();

// automatic id assignment for demo purposes
// do not use this in production, duplicated ids could be generated!
String autoId() =>
    'demo_id_${_rnd.nextInt(65536)}_${DateTime.now().millisecondsSinceEpoch}';

class ToDo extends BaseDocumentWithEtag {
  ToDo._(
    this.id,
    this.owner,
    this.label,
    this.description,
    this.dueDate,
    this.completedDate,
  );

  ToDo(
    String owner,
    String label, {
    String? description,
    DateTime? dueDate,
    DateTime? completedDate,
  }) : this._(autoId(), owner, label, description, dueDate, completedDate);

  @override
  final String id;

  final String owner;

  String label;
  String? description;
  DateTime? dueDate;
  DateTime? completedDate;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'owner': owner,
        'label': label,
        if (description != null) 'description': description,
        'due-date': dueDate?.toUtc().toIso8601String(),
        'completed': completedDate?.toUtc().toIso8601String(),
      };

  static ToDo fromJson(Map json) {
    final todo = ToDo._(
      json['id'],
      json['owner'] ?? '(unassigned)',
      json['label'],
      json['description'],
      DateTime.tryParse(json['due-date'] ?? '')?.toLocal(),
      DateTime.tryParse(json['completed'] ?? '')?.toLocal(),
    );
    todo.setEtag(json);
    return todo;
  }
}
