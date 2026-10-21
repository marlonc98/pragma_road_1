import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/petition_status_entity.dart';
import 'package:gestor_tareas_personales/domain/repositories/note_repository.dart';

class SaveNoteUseCase {
  final NoteRepository noteRepository;

  SaveNoteUseCase({required this.noteRepository});

  Future<PetitionStatusEntity<void>> addNote(NoteEntity note) =>
      noteRepository.addNote(note);

  Future<PetitionStatusEntity<void>> updateNote(NoteEntity note) =>
      noteRepository.updateNote(note);
}
