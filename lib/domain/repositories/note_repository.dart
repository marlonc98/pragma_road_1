import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/petition_status_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/search_result_entity.dart';

abstract class NoteRepository {
  Future<PetitionStatusEntity<void>> addNote(NoteEntity note);
  Future<PetitionStatusEntity<void>> updateNote(NoteEntity note);
  Future<PetitionStatusEntity<void>> deleteNote(String id);
  Future<PetitionStatusEntity<SearchResultEntity<NoteEntity>>> getNotes();
}
