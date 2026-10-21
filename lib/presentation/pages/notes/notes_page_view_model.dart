import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/petition_status_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/search_result_entity.dart';
import 'package:gestor_tareas_personales/presentation/constants/text_constants.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/note_editor_page.dart';
import 'package:gestor_tareas_personales/presentation/pages/notes/notes_page.dart';
import 'package:gestor_tareas_personales/presentation/pages/notes/widgets/note_options_bottom_sheet.dart';
import 'package:gestor_tareas_personales/presentation/utils/view_model.dart';

class NotesPageViewModel extends ViewModel<NotesPage> {
  NotesPageViewModel({
    required super.context,
    required super.widget,
    required super.ref,
    required super.isMounted,
  }) {
    handleLoadNotes();
  }

  final TextEditingController searchController = TextEditingController();
  Timer? _searchDebounce;
  int _searchRequest = 0;

  PetitionStatusEntity<SearchResultEntity<NoteEntity>> notes =
      PetitionStatusEntity<SearchResultEntity<NoteEntity>>.loading();

  String get query => searchController.text.trim();
  List<NoteEntity> get pinnedNotes =>
      notes.data?.data.where((note) => note.pinned).toList() ?? [];
  List<NoteEntity> get otherNotes =>
      notes.data?.data.where((note) => !note.pinned).toList() ?? [];

  Future<void> handleLoadNotes() async {
    // Evita que una búsqueda vieja pise el resultado de una más reciente
    final request = ++_searchRequest;
    final response = await ref
        .read(getNotesUseCaseProvider)
        .getNotes(query: query);
    if (request != _searchRequest || !mounted) return;
    notes = response;
    notifyListeners();
  }

  void handleRetry() {
    notes = PetitionStatusEntity<SearchResultEntity<NoteEntity>>.loading();
    notifyListeners();
    handleLoadNotes();
  }

  void handleSearchChanged(String _) {
    notifyListeners();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), handleLoadNotes);
  }

  void handleClearSearch() {
    searchController.clear();
    handleSearchChanged('');
  }

  Future<void> handleCreateNote() => _openEditor(null);

  Future<void> handleOpenNote(NoteEntity note) => _openEditor(note);

  Future<void> _openEditor(NoteEntity? note) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await context.push(NoteEditorPage.route, extra: note);
    if (mounted) await handleLoadNotes();
  }

  Future<void> handleNoteOptions(NoteEntity note) async {
    // Sin esto el buscador recupera el foco al cerrar el menú
    FocusManager.instance.primaryFocus?.unfocus();
    final option = await showNoteOptionsBottomSheet(context, note: note);
    if (option == null || !mounted) return;
    final response = switch (option) {
      NoteOption.pin => await ref.read(pinNoteUseCaseProvider).togglePin(note),
      NoteOption.delete =>
        await ref.read(deleteNoteUseCaseProvider).deleteNote(note.id),
    };
    if (!mounted) return;
    final i18n = ref.read(localizationStateProvider.notifier).translate;
    if (!response.isSuccess) {
      _showMessage(i18n(response.error ?? ''));
      return;
    }
    if (option == NoteOption.delete) {
      _showMessage(i18n(TextConstants.noteDeleted));
    }
    await handleLoadNotes();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }
}
