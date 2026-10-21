import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/petition_status_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/search_result_entity.dart';
import 'package:gestor_tareas_personales/domain/repositories/note_repository.dart';

// TODO: conectar a la fuente de datos
class NoteRepositoryImpl extends NoteRepository {
  @override
  Future<PetitionStatusEntity<void>> addNote(NoteEntity note) {
    throw UnimplementedError();
  }

  @override
  Future<PetitionStatusEntity<void>> updateNote(NoteEntity note) {
    throw UnimplementedError();
  }

  @override
  Future<PetitionStatusEntity<void>> deleteNote(String id) {
    throw UnimplementedError();
  }

  @override
  Future<PetitionStatusEntity<SearchResultEntity<NoteEntity>>> getNotes({
    String? query,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PetitionStatusEntity<int>> countPinnedNotes() {
    throw UnimplementedError();
  }
}
