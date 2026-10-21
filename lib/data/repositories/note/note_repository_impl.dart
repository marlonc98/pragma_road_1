import 'package:gestor_tareas_personales/data/repositories/note/api/count_pinned_notes_api_impl.dart';
import 'package:gestor_tareas_personales/data/repositories/note/api/delete_note_api_impl.dart';
import 'package:gestor_tareas_personales/data/repositories/note/api/get_note_by_id_api_impl.dart';
import 'package:gestor_tareas_personales/data/repositories/note/api/get_notes_api_impl.dart';
import 'package:gestor_tareas_personales/data/repositories/note/api/save_note_api_impl.dart';
import 'package:gestor_tareas_personales/data/repositories/note/api/set_pinned_api_impl.dart';
import 'package:gestor_tareas_personales/domain/constants/errors_constants.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/petition_status_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/search_result_entity.dart';
import 'package:gestor_tareas_personales/domain/repositories/note_repository.dart';

class NoteRepositoryImpl extends NoteRepository {
  /// Cada nota se guarda en {notePrefix}_{id}
  static const String notePrefix = 'sp_note';

  /// Solo los ids de las notas fijadas
  static const String pinnedNotesKey = 'sp_pinned_notes';

  static const int previewMaxLines = 10;

  @override
  Future<PetitionStatusEntity<void>> addNote(NoteEntity note) =>
      _run(() => saveNoteApiImpl(notePrefix, note));

  @override
  Future<PetitionStatusEntity<void>> updateNote(NoteEntity note) =>
      _run(() => saveNoteApiImpl(notePrefix, note));

  @override
  Future<PetitionStatusEntity<void>> deleteNote(String id) =>
      _run(() => deleteNoteApiImpl(notePrefix, pinnedNotesKey, id));

  @override
  Future<PetitionStatusEntity<SearchResultEntity<NoteEntity>>> getNotes({
    String? query,
  }) => _run(() async {
    final notes = await getNotesApiImpl(
      notePrefix,
      pinnedNotesKey,
      previewMaxLines: previewMaxLines,
      query: query,
    );
    return SearchResultEntity(
      currentPage: 1,
      totalItems: notes.length,
      data: notes,
      itemsPerPage: notes.length,
      lastpage: 1,
    );
  });

  @override
  Future<PetitionStatusEntity<NoteEntity>> getNoteById(String id) async {
    final response = await _run(
      () => getNoteByIdApiImpl(notePrefix, pinnedNotesKey, id),
    );
    if (response.isSuccess && response.data == null) {
      return PetitionStatusEntity.fromError(ErrorsConstants.noteNotFound);
    }
    return response.map((note) => note!);
  }

  @override
  Future<PetitionStatusEntity<void>> setPinned(String id, bool pinned) =>
      _run(() => setPinnedApiImpl(pinnedNotesKey, id, pinned));

  @override
  Future<PetitionStatusEntity<int>> countPinnedNotes() =>
      _run(() => countPinnedNotesApiImpl(pinnedNotesKey));

  Future<PetitionStatusEntity<T>> _run<T>(Future<T> Function() call) async {
    try {
      return PetitionStatusEntity.success(data: await call());
    } catch (error) {
      return PetitionStatusEntity.fromError(error);
    }
  }
}
