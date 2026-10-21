import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/petition_status_entity.dart';
import 'package:gestor_tareas_personales/domain/repositories/note_repository.dart';

class GetPinnedNotesUseCase {
  final NoteRepository noteRepository;

  GetPinnedNotesUseCase({required this.noteRepository});

  Future<PetitionStatusEntity<List<NoteEntity>>> getPinnedNotes({
    String? query,
  }) => noteRepository.getPinnedNotes(query: query?.trim());
}
