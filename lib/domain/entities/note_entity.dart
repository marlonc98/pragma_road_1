class NoteEntity {
  final String id;
  final String? title;
  final String? content;
  final bool pinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteEntity({
    required this.id,
    this.title,
    this.content,
    this.pinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasTitle => title?.trim().isNotEmpty ?? false;
  bool get hasContent => content?.trim().isNotEmpty ?? false;

  bool get isEmpty => !hasTitle && !hasContent;

  NoteEntity copyWith({
    String? title,
    String? content,
    bool? pinned,
    DateTime? updatedAt,
  }) {
    return NoteEntity(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      pinned: pinned ?? this.pinned,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
