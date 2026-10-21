import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';

/// Clave directa de una nota: {prefijo}_{id}
String noteKey(String notePrefix, String id) => '${notePrefix}_$id';

/// pinned no se guarda en la nota: sale de la lista de ids fijados
Map<String, dynamic> noteToJson(NoteEntity note) => {
  'id': note.id,
  'title': note.title,
  'content': note.content,
  'createdAt': note.createdAt.toIso8601String(),
  'updatedAt': note.updatedAt.toIso8601String(),
};

NoteEntity noteFromJson(Map<String, dynamic> json, {required bool pinned}) =>
    NoteEntity(
      id: json['id'] as String,
      title: json['title'] as String?,
      content: json['content'] as String?,
      pinned: pinned,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
