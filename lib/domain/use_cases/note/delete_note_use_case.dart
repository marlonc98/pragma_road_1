import 'package:gestor_tareas_personales/domain/entities/petition_status_entity.dart';
import 'package:gestor_tareas_personales/domain/repositories/note_repository.dart';

class DeleteNoteUseCase {
  final NoteRepository noteRepository;

  DeleteNoteUseCase({required this.noteRepository});

  Future<PetitionStatusEntity<void>> deleteNote(String id) =>
      noteRepository.deleteNote(id);
}
