import 'package:flutter/material.dart';
import 'package:gestor_tareas_personales/presentation/constants/markdown_constants.dart';

/// Pinta el primer renglón con el estilo del título y aplica el formato
/// Markdown (negrita, cursiva, tachado y listas).
/// Las marcas siguen en el texto (si no, el cursor se descuadra), pero se
/// dibujan invisibles y sin ancho, como en Google Keep. Para que no estorben,
/// el cursor y el borrado se las saltan.
/// Respeta el rango que el teclado está componiendo (autocompletado);
/// si se ignora, teclados como Gboard se traban al escribir.
class NoteEditingController extends TextEditingController {
  TextStyle? titleStyle;
  TextStyle markerStyle = const TextStyle(color: Colors.grey);

  NoteEditingController({super.text});

  static const _hiddenMarkerStyle = TextStyle(
    fontSize: 0.01,
    color: Colors.transparent,
    letterSpacing: 0,
  );

  static final _bold = RegExp.escape(MarkdownConstants.bold);
  static final _italic = RegExp.escape(MarkdownConstants.italic);
  static final _strikethrough = RegExp.escape(MarkdownConstants.strikethrough);

  /// Grupo 1: negrita y cursiva, grupo 2: negrita, grupo 3: tachado,
  /// grupo 4: cursiva, grupo 5: par vacío (recién insertado con la barra).
  /// El orden importa: ***x*** se prueba antes que **x**
  static final _inlinePattern = RegExp(
    '$_bold$_italic(.+?)$_italic$_bold'
    '|$_bold(.+?)$_bold'
    '|$_strikethrough(.+?)$_strikethrough'
    '|$_italic(?!$_italic)(.+?)(?<!$_italic)$_italic'
    '|($_bold$_bold|$_strikethrough$_strikethrough|$_italic$_italic)',
  );

  /// Pares vacíos, del más largo al más corto
  static const _emptyPairMarkers = [
    MarkdownConstants.bold + MarkdownConstants.italic,
    MarkdownConstants.bold,
    MarkdownConstants.strikethrough,
    MarkdownConstants.italic,
  ];

  //#region ------------- Pintado -------------------------//
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final ranges = <_StyledRange>[];

    final breakIndex = text.indexOf('\n');
    final titleEnd = breakIndex == -1 ? text.length : breakIndex;
    if (titleStyle != null) ranges.add(_StyledRange(0, titleEnd, titleStyle!));

    var lineStart = 0;
    for (final line in text.split('\n')) {
      // El primer renglón es el título, no puede ser lista
      if (lineStart > 0 && line.startsWith(MarkdownConstants.listPrefix)) {
        ranges.add(
          _StyledRange(
            lineStart,
            lineStart + MarkdownConstants.listPrefix.length,
            markerStyle,
          ),
        );
      }
      lineStart += line.length + 1;
    }

    for (final format in _parseFormats(text)) {
      if (format.style != null) {
        ranges.add(
          _StyledRange(format.innerStart, format.innerEnd, format.style!),
        );
      }
      ranges
        ..add(_StyledRange(format.start, format.innerStart, _hiddenMarkerStyle))
        ..add(_StyledRange(format.innerEnd, format.end, _hiddenMarkerStyle));
    }

    if (withComposing && value.isComposingRangeValid) {
      ranges.add(
        _StyledRange(
          value.composing.start,
          value.composing.end,
          const TextStyle(decoration: TextDecoration.underline),
        ),
      );
    }

    return TextSpan(style: style, children: _buildSegments(ranges));
  }

  /// Corta el texto donde empieza o termina algún estilo y combina
  /// los estilos que cubren cada tramo
  List<TextSpan> _buildSegments(List<_StyledRange> ranges) {
    final boundaries = <int>{
      0,
      text.length,
      for (final range in ranges) ...[range.start, range.end],
    }.toList()..sort();

    final segments = <TextSpan>[];
    for (var i = 0; i < boundaries.length - 1; i++) {
      final start = boundaries[i];
      final end = boundaries[i + 1];
      if (start == end) continue;
      TextStyle? segmentStyle;
      for (final range in ranges) {
        if (range.start <= start && range.end >= end) {
          segmentStyle = _merge(segmentStyle, range.style);
        }
      }
      segments.add(
        TextSpan(text: text.substring(start, end), style: segmentStyle),
      );
    }
    return segments;
  }

  /// Como TextStyle.merge, pero suma las decoraciones (tachado + subrayado)
  TextStyle _merge(TextStyle? base, TextStyle other) {
    if (base == null) return other;
    final decorations = [?base.decoration, ?other.decoration];
    return base
        .merge(other)
        .copyWith(
          decoration: decorations.isEmpty
              ? null
              : TextDecoration.combine(decorations),
        );
  }
  //#endregion Pintado

  //#region ------------- Cursor y borrado -------------------------//
  @override
  set value(TextEditingValue newValue) {
    final oldValue = super.value;
    if (newValue.text == oldValue.text) {
      super.value = _skipMarkersOnMove(oldValue, newValue);
      return;
    }
    super.value =
        _handleLineBreak(oldValue, newValue) ??
        _skipMarkersOnDelete(oldValue, newValue);
  }

  /// Enter:
  /// - El formato se reconoce por renglón, así que un Enter dentro de una
  ///   negrita la partiría y dejaría las marcas a la vista. Se cierra el
  ///   formato antes del salto y se reabre después: **ho|la** → **ho**\n**la**
  /// - En un item de lista se continúa la lista; en un item vacío se termina
  TextEditingValue? _handleLineBreak(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!oldValue.selection.isValid || !oldValue.selection.isCollapsed) {
      return null;
    }
    final oldText = oldValue.text;
    var position = oldValue.selection.baseOffset;
    final insertedLineBreak =
        newValue.text == oldText.replaceRange(position, position, '\n');
    if (!insertedLineBreak) return null;

    final formats = _parseFormats(oldText);
    // En el borde de un formato el salto va por fuera de las marcas
    var moved = true;
    while (moved) {
      moved = false;
      for (final format in formats) {
        if (position == format.innerEnd && position != format.end) {
          position = format.end;
          moved = true;
        } else if (position == format.innerStart && position != format.start) {
          position = format.start;
          moved = true;
        }
      }
    }

    final enclosing =
        formats
            .where(
              (format) =>
                  format.innerStart < position && position < format.innerEnd,
            )
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    final closing = [
      for (final format in enclosing.reversed)
        oldText.substring(format.innerEnd, format.end),
    ].join();
    final opening = [
      for (final format in enclosing)
        oldText.substring(format.start, format.innerStart),
    ].join();
    const listPrefix = MarkdownConstants.listPrefix;
    final lineStart = position == 0
        ? 0
        : oldText.lastIndexOf('\n', position - 1) + 1;
    final lineEnd = oldText.indexOf('\n', position);
    final line = oldText.substring(
      lineStart,
      lineEnd == -1 ? oldText.length : lineEnd,
    );
    // El primer renglón es el título, no puede ser lista
    final isListItem = lineStart > 0 && line.startsWith(listPrefix);
    if (isListItem && line == listPrefix) {
      return TextEditingValue(
        text: oldText.replaceRange(
          lineStart,
          lineStart + listPrefix.length,
          '',
        ),
        selection: TextSelection.collapsed(offset: lineStart),
      );
    }

    final inserted = '$closing\n${isListItem ? listPrefix : ''}$opening';
    return TextEditingValue(
      text: oldText.replaceRange(position, position, inserted),
      selection: TextSelection.collapsed(offset: position + inserted.length),
    );
  }

  TextEditingValue _skipMarkersOnMove(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!oldValue.selection.isValid ||
        !newValue.selection.isValid ||
        !newValue.selection.isCollapsed) {
      return newValue;
    }
    final from = oldValue.selection.baseOffset;
    final to = newValue.selection.baseOffset;
    if (from == to) return newValue;
    final direction = to > from ? 1 : -1;
    final markers = _markerRanges(newValue.text);

    var offset = _snapOutOfMarker(to, direction, markers);
    // Con las flechas, si el paso solo cruzó marcas invisibles el cursor
    // no se movería en pantalla: avanza un carácter más
    if (oldValue.selection.isCollapsed && (to - from).abs() == 1) {
      while (offset != from &&
          _isHidden(from, offset, markers) &&
          offset + direction >= 0 &&
          offset + direction <= newValue.text.length) {
        offset = _snapOutOfMarker(offset + direction, direction, markers);
      }
    }
    if (offset == to) return newValue;
    return newValue.copyWith(
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  TextEditingValue _skipMarkersOnDelete(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    final caret = newValue.selection.baseOffset;
    final deletedOne =
        oldText.length - newValue.text.length == 1 &&
        oldValue.selection.isCollapsed &&
        newValue.selection.isCollapsed;
    if (!deletedOne) return newValue;
    final isBackspace = oldValue.selection.baseOffset == caret + 1;
    final isForwardDelete = oldValue.selection.baseOffset == caret;
    if (!isBackspace && !isForwardDelete) return newValue;

    // Borrar justo después de tocar un botón de formato lo cancela
    final emptyPair = _emptyPairAround(oldText, oldValue.selection.baseOffset);
    if (emptyPair != null) return emptyPair;

    final markers = _markerRanges(oldText);
    var index = caret; // posición del carácter borrado en el texto anterior
    if (!markers.any((marker) => _contains(marker, index))) {
      return _emptyPairAround(newValue.text, caret) ?? newValue;
    }

    final step = isBackspace ? -1 : 1;
    while (index >= 0 &&
        index < oldText.length &&
        markers.any((marker) => _contains(marker, index))) {
      index += step;
    }
    if (index < 0 || index >= oldText.length) return oldValue;

    final skipped = TextEditingValue(
      text: oldText.replaceRange(index, index + 1, ''),
      selection: TextSelection.collapsed(offset: isBackspace ? index : caret),
    );
    return _emptyPairAround(skipped.text, skipped.selection.baseOffset) ??
        skipped;
  }

  /// Si el cursor quedó entre un par de marcas sin texto (****, ~~~~, **),
  /// devuelve el texto sin ese par
  TextEditingValue? _emptyPairAround(String text, int caret) {
    for (final marker in _emptyPairMarkers) {
      final length = marker.length;
      final isPair =
          caret >= length &&
          caret + length <= text.length &&
          text.substring(caret - length, caret) == marker &&
          text.substring(caret, caret + length) == marker;
      if (isPair) {
        return TextEditingValue(
          text: text.replaceRange(caret - length, caret + length, ''),
          selection: TextSelection.collapsed(offset: caret - length),
        );
      }
    }
    return null;
  }

  int _snapOutOfMarker(int offset, int direction, List<TextRange> markers) {
    var snapped = offset;
    var moved = true;
    while (moved) {
      moved = false;
      for (final marker in markers) {
        if (marker.start < snapped && snapped < marker.end) {
          snapped = direction > 0 ? marker.end : marker.start;
          moved = true;
        }
      }
    }
    return snapped;
  }

  /// Si todos los caracteres entre [a] y [b] son marcas invisibles
  bool _isHidden(int a, int b, List<TextRange> markers) {
    final start = a < b ? a : b;
    final end = a < b ? b : a;
    for (var index = start; index < end; index++) {
      if (!markers.any((marker) => _contains(marker, index))) return false;
    }
    return true;
  }

  bool _contains(TextRange range, int index) =>
      range.start <= index && index < range.end;
  //#endregion Cursor y borrado

  //#region ------------- Parseo -------------------------//
  List<TextRange> _markerRanges(String text) => [
    for (final format in _parseFormats(text)) ...[
      TextRange(start: format.start, end: format.innerStart),
      TextRange(start: format.innerEnd, end: format.end),
    ],
  ];

  List<_InlineFormat> _parseFormats(String text, [int offset = 0]) {
    final formats = <_InlineFormat>[];
    for (final match in _inlinePattern.allMatches(text)) {
      final start = offset + match.start;
      final end = offset + match.end;
      if (match[5] != null) {
        final half = match[5]!.length ~/ 2;
        formats.add(_InlineFormat(start, start + half, end - half, end, null));
        continue;
      }
      final (marker, style, inner) = switch (match) {
        _ when match[1] != null => (
          MarkdownConstants.bold + MarkdownConstants.italic,
          const TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
          match[1]!,
        ),
        _ when match[2] != null => (
          MarkdownConstants.bold,
          const TextStyle(fontWeight: FontWeight.bold),
          match[2]!,
        ),
        _ when match[3] != null => (
          MarkdownConstants.strikethrough,
          const TextStyle(decoration: TextDecoration.lineThrough),
          match[3]!,
        ),
        _ => (
          MarkdownConstants.italic,
          const TextStyle(fontStyle: FontStyle.italic),
          match[4]!,
        ),
      };
      final innerStart = start + marker.length;
      formats
        ..add(
          _InlineFormat(
            start,
            innerStart,
            innerStart + inner.length,
            end,
            style,
          ),
        )
        // Recursivo para combinar formatos, por ejemplo ~~**tachado y negrita**~~
        ..addAll(_parseFormats(inner, innerStart));
    }
    return formats;
  }

  //#endregion Parseo
}

class _StyledRange {
  final int start;
  final int end;
  final TextStyle style;

  const _StyledRange(this.start, this.end, this.style);
}

/// Un formato encontrado en el texto: marcas en [start, innerStart) y
/// [innerEnd, end), contenido en medio. [style] es null en un par vacío
class _InlineFormat {
  final int start;
  final int innerStart;
  final int innerEnd;
  final int end;
  final TextStyle? style;

  const _InlineFormat(
    this.start,
    this.innerStart,
    this.innerEnd,
    this.end,
    this.style,
  );
}
