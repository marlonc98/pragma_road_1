import 'package:gestor_tareas_personales/domain/constants/errors_constants.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/petition_status_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/search_result_entity.dart';
import 'package:gestor_tareas_personales/domain/repositories/note_repository.dart';

DateTime _daysAgo(int days) => DateTime.now().subtract(Duration(days: days));

final List<NoteEntity> _fakeNotes = [
  NoteEntity(
    id: '1',
    title: 'Lista del mercado',
    content: 'Leche\nHuevos\nPan integral\nCafé\nAguacates\nTomates',
    pinned: true,
    createdAt: _daysAgo(10),
    updatedAt: _daysAgo(1),
  ),
  NoteEntity(
    id: '2',
    title: 'Ideas para el fin de semana',
    content: 'Ir al parque, ver una película y probar la receta de lasaña.',
    createdAt: _daysAgo(9),
    updatedAt: _daysAgo(2),
  ),
  NoteEntity(
    id: '3',
    content: 'Llamar al banco antes del viernes',
    createdAt: _daysAgo(8),
    updatedAt: _daysAgo(3),
  ),
  NoteEntity(
    id: '4',
    title: 'Contraseña del wifi en la oficina',
    createdAt: _daysAgo(7),
    updatedAt: _daysAgo(4),
  ),
  NoteEntity(
    id: '5',
    title: 'Libros pendientes',
    content: 'Clean Architecture\nEl programador pragmático\nRefactoring\nDomain-Driven Design',
    pinned: true,
    createdAt: _daysAgo(6),
    updatedAt: _daysAgo(5),
  ),
  NoteEntity(
    id: '6',
    content: 'Recordar revisar los pull requests pendientes y responder los comentarios del equipo antes de la daily.',
    createdAt: _daysAgo(5),
    updatedAt: _daysAgo(5),
  ),
  NoteEntity(
    id: '7',
    title: 'Cumpleaños de mamá',
    content: '12 de noviembre, comprar flores',
    createdAt: _daysAgo(4),
    updatedAt: _daysAgo(6),
  ),
  NoteEntity(
    id: '8',
    title: 'Rutina gimnasio',
    content: 'Lunes: pierna\nMiércoles: espalda\nViernes: pecho y brazo',
    createdAt: _daysAgo(3),
    updatedAt: _daysAgo(7),
  ),
];

class NoteRepositoryMock extends NoteRepository {
  final Duration _delay = const Duration(milliseconds: 400);

  @override
  Future<PetitionStatusEntity<void>> addNote(NoteEntity note) async {
    await Future.delayed(_delay);
    _fakeNotes.add(note);
    return PetitionStatusEntity.success();
  }

  @override
  Future<PetitionStatusEntity<void>> updateNote(NoteEntity note) async {
    await Future.delayed(_delay);
    final index = _fakeNotes.indexWhere((element) => element.id == note.id);
    if (index == -1) return PetitionStatusEntity.fromError(Exception());
    _fakeNotes[index] = note;
    return PetitionStatusEntity.success();
  }

  @override
  Future<PetitionStatusEntity<void>> deleteNote(String id) async {
    await Future.delayed(_delay);
    _fakeNotes.removeWhere((element) => element.id == id);
    return PetitionStatusEntity.success();
  }

  @override
  Future<PetitionStatusEntity<SearchResultEntity<NoteEntity>>> getNotes({
    String? query,
  }) async {
    await Future.delayed(_delay);
    final search = query?.toLowerCase() ?? '';
    final notes =
        _fakeNotes
            .where(
              (note) =>
                  search.isEmpty ||
                  (note.title?.toLowerCase().contains(search) ?? false) ||
                  (note.content?.toLowerCase().contains(search) ?? false),
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return PetitionStatusEntity.success(
      data: SearchResultEntity(
        currentPage: 1,
        totalItems: notes.length,
        data: notes,
        itemsPerPage: notes.length,
        lastpage: 1,
      ),
    );
  }

  @override
  Future<PetitionStatusEntity<NoteEntity>> getNoteById(String id) async {
    await Future.delayed(_delay);
    final index = _fakeNotes.indexWhere((element) => element.id == id);
    if (index == -1) {
      return PetitionStatusEntity.fromError(ErrorsConstants.noteNotFound);
    }
    return PetitionStatusEntity.success(data: _fakeNotes[index]);
  }

  @override
  Future<PetitionStatusEntity<void>> setPinned(String id, bool pinned) async {
    await Future.delayed(_delay);
    final index = _fakeNotes.indexWhere((element) => element.id == id);
    if (index == -1) {
      return PetitionStatusEntity.fromError(ErrorsConstants.noteNotFound);
    }
    _fakeNotes[index] = _fakeNotes[index].copyWith(pinned: pinned);
    return PetitionStatusEntity.success();
  }

  @override
  Future<PetitionStatusEntity<int>> countPinnedNotes() async {
    return PetitionStatusEntity.success(
      data: _fakeNotes.where((note) => note.pinned).length,
    );
  }
}
