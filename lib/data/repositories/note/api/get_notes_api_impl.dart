import 'dart:convert';

import 'package:gestor_tareas_personales/data/repositories/note/api/note_storage.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notas para listar, de la más reciente a la más vieja.
/// El contenido se recorta a [previewMaxLines] renglones con ...
Future<List<NoteEntity>> getNotesApiImpl(
  String notePrefix,
  String pinnedNotesKey, {
  required int previewMaxLines,
  String? query,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final pinnedIds = prefs.getStringList(pinnedNotesKey) ?? [];
  final search = query?.toLowerCase() ?? '';

  final notes = <NoteEntity>[];
  for (final key in prefs.getKeys()) {
    if (!key.startsWith(noteKey(notePrefix, ''))) continue;
    final json = jsonDecode(prefs.getString(key)!) as Map<String, dynamic>;
    final note = noteFromJson(json, pinned: pinnedIds.contains(json['id']));
    final matches =
        search.isEmpty ||
        (note.title?.toLowerCase().contains(search) ?? false) ||
        (note.content?.toLowerCase().contains(search) ?? false);
    if (matches) notes.add(_preview(note, previewMaxLines));
  }
  return notes..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
}

NoteEntity _preview(NoteEntity note, int maxLines) {
  final lines = note.content?.split('\n');
  if (lines == null || lines.length <= maxLines) return note;
  return note.copyWith(content: '${lines.take(maxLines).join('\n')}...');
}
