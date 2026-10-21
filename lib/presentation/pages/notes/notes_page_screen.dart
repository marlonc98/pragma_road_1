import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/search_result_entity.dart';
import 'package:gestor_tareas_personales/presentation/constants/text_constants.dart';
import 'package:gestor_tareas_personales/presentation/pages/notes/notes_page_view_model.dart';
import 'package:gestor_tareas_personales/presentation/pages/notes/widgets/notes_grid_widget.dart';
import 'package:gestor_tareas_personales/presentation/pages/notes/widgets/notes_search_bar_widget.dart';
import 'package:gestor_tareas_personales/presentation/widgets/loader_screen_widget.dart';

class NotesPageScreen extends ConsumerWidget {
  final NotesPageViewModel vm;
  const NotesPageScreen({super.key, required this.vm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localizationStateProvider);
    final i18n = ref.read(localizationStateProvider.notifier).translate;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: i18n(TextConstants.notesCreate),
        onPressed: vm.handleCreateNote,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: NotesSearchBarWidget(
                controller: vm.searchController,
                hintText: i18n(TextConstants.notesSearchHint),
                onChanged: vm.handleSearchChanged,
                onClear: vm.handleClearSearch,
              ),
            ),
            Expanded(
              child: LoaderScreenWidget<SearchResultEntity<NoteEntity>>(
                status: vm.notes,
                onRetry: vm.handleRetry,
                noResultsScreen: true,
                customNoResultsOperation: vm.notes.data?.isEmpty ?? false,
                messageNoResults: i18n(
                  vm.query.isEmpty
                      ? TextConstants.notesEmpty
                      : TextConstants.notesNoResults,
                ),
                builder: (context, _) => _buildNotes(context, i18n),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotes(
    BuildContext context,
    String Function(String, {Map<String, dynamic>? values}) i18n,
  ) {
    final pinned = vm.pinnedNotes;
    final others = vm.otherNotes;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      children: [
        if (pinned.isNotEmpty) ...[
          _buildSectionTitle(context, i18n(TextConstants.notesPinned)),
          NotesGridWidget(
            notes: pinned,
            onTap: vm.handleOpenNote,
            onLongPress: vm.handleNoteOptions,
          ),
        ],
        if (others.isNotEmpty) ...[
          if (pinned.isNotEmpty)
            _buildSectionTitle(context, i18n(TextConstants.notesOthers)),
          NotesGridWidget(
            notes: others,
            onTap: vm.handleOpenNote,
            onLongPress: vm.handleNoteOptions,
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
