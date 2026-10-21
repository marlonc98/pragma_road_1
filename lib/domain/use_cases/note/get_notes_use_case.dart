import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/petition_status_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/search_result_entity.dart';
import 'package:gestor_tareas_personales/domain/repositories/note_repository.dart';

class GetNotesUseCase {
  final NoteRepository noteRepository;

  GetNotesUseCase({required this.noteRepository});

  Future<PetitionStatusEntity<SearchResultEntity<NoteEntity>>> getNotes({
    String? query,
  }) => noteRepository.getNotes(query: query?.trim());
}
