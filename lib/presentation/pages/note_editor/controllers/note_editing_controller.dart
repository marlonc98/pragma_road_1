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

  /// Pares vacíos, del más largo al más corto
  static const _emptyPairMarkers = [
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
      if (format.type != null) {
        ranges.add(
          _StyledRange(format.innerStart, format.innerEnd, format.type!.style),
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

  //#region ------------- Formato con la barra -------------------------//
  /// Pone [type] en la selección o, si ya lo tiene, se lo quita solo a ella
  /// (en medio de una negrita: **hola |dssd| hosad** → **hola **dssd** hosad**)
  void toggleFormat(MarkdownFormat type) {
    final selection = this.selection;
    if (!selection.isValid) return;
    final formats = _parseFormats(text);
    final markers = _markerRanges(text);
    final enclosing =
        formats
            .where(
              (format) =>
                  format.type == type &&
                  format.innerStart <= selection.start &&
                  selection.end <= format.innerEnd,
            )
            .toList()
          ..sort((a, b) => b.innerStart.compareTo(a.innerStart));
    super.value = enclosing.isEmpty
        ? _applyFormat(type, selection.start, selection.end, formats)
        : _removeFormat(
            enclosing.first,
            selection.start,
            selection.end,
            markers,
          );
  }

  TextEditingValue _applyFormat(
    MarkdownFormat type,
    int selectionStart,
    int selectionEnd,
    List<_InlineFormat> formats,
  ) {
    // Las marcas van pegadas al texto, no a los espacios de los bordes
    var start = selectionStart;
    var end = selectionEnd;
    while (start < end && _isSpace(text[start])) {
      start++;
    }
    while (end > start && _isSpace(text[end - 1])) {
      end--;
    }
    if (start == end) {
      start = selectionStart;
      end = selectionEnd;
    }
    // Si dentro había pedazos con el mismo formato se unen en uno solo
    final inner = [
      for (final format in formats)
        if (format.type == type &&
            format.start >= start &&
            format.end <= end) ...[
          TextRange(start: format.start, end: format.innerStart),
          TextRange(start: format.innerEnd, end: format.end),
        ],
    ]..sort((a, b) => b.start.compareTo(a.start));
    var newText = text;
    var newEnd = end;
    for (final marker in inner) {
      newText = newText.replaceRange(marker.start, marker.end, '');
      newEnd -= marker.end - marker.start;
    }
    final marker = type.marker;
    final selected = newText.substring(start, newEnd);
    return TextEditingValue(
      text: newText.replaceRange(start, newEnd, '$marker$selected$marker'),
      selection: TextSelection(
        baseOffset: start + marker.length,
        extentOffset: newEnd + marker.length,
      ),
    );
  }

  TextEditingValue _removeFormat(
    _InlineFormat format,
    int start,
    int end,
    List<TextRange> markers,
  ) {
    final opening = text.substring(format.start, format.innerStart);
    final closing = text.substring(format.innerEnd, format.end);
    // Entre el borde y la selección solo hay marcas invisibles: cuenta como
    // si la selección llegara al borde
    final atStart = _isHidden(format.innerStart, start, markers);
    final atEnd = _isHidden(end, format.innerEnd, markers);

    if (start == end) {
      // Sin selección: lo que se escriba en el cursor sale sin el formato
      if (atStart) {
        return value.copyWith(
          selection: TextSelection.collapsed(offset: format.start),
        );
      }
      if (atEnd) {
        return value.copyWith(
          selection: TextSelection.collapsed(offset: format.end),
        );
      }
      return TextEditingValue(
        text: text.replaceRange(start, start, '$closing$opening'),
        selection: TextSelection.collapsed(offset: start + closing.length),
      );
    }

    // Las marcas nuevas van pegadas a las palabras que siguen con formato:
    // **hola |dssd| hosad** → **hola** dssd **hosad**
    var openingAt = end;
    while (openingAt < format.innerEnd && _isSpace(text[openingAt])) {
      openingAt++;
    }
    var closingAt = start;
    while (closingAt > format.innerStart && _isSpace(text[closingAt - 1])) {
      closingAt--;
    }

    var newText = atEnd
        ? text.replaceRange(format.innerEnd, format.end, '')
        : text.replaceRange(openingAt, openingAt, opening);
    var newStart = start;
    var newEnd = end;
    if (atStart) {
      newText = newText.replaceRange(format.start, format.innerStart, '');
      newStart -= opening.length;
      newEnd -= opening.length;
    } else {
      newText = newText.replaceRange(closingAt, closingAt, closing);
      newStart += closing.length;
      newEnd += closing.length;
    }
    return TextEditingValue(
      text: newText,
      selection: TextSelection(baseOffset: newStart, extentOffset: newEnd),
    );
  }
  //#endregion Formato con la barra

  //#region ------------- Parseo -------------------------//
  List<TextRange> _markerRanges(String text) => [
    for (final format in _parseFormats(text)) ...[
      TextRange(start: format.start, end: format.innerStart),
      TextRange(start: format.innerEnd, end: format.end),
    ],
  ];

  /// Parser con pila, como los de Markdown: recorre cada renglón y empareja
  /// cada marca de cierre con la apertura más cercana del mismo tipo, así
  /// soporta formatos anidados y combinados en cualquier orden.
  /// Cada formato usa un carácter distinto (** negrita, _ cursiva, ~~ tachado)
  /// para que sus marcas nunca se confundan aunque queden pegadas
  List<_InlineFormat> _parseFormats(String text) {
    final formats = <_InlineFormat>[];
    var lineStart = 0;
    for (final line in text.split('\n')) {
      _parseLine(line, lineStart, formats);
      lineStart += line.length + 1;
    }
    return formats;
  }

  void _parseLine(String line, int offset, List<_InlineFormat> formats) {
    final openers = <_Delimiter>[];
    final unmatched = <_Delimiter>[];
    for (final run in _delimiterRuns(line)) {
      final format = _formatsByChar[run.char]!;
      final used = format.marker.length;
      var closeStart = run.start;
      var remaining = run.length;
      while (remaining >= used) {
        final index = openers.lastIndexWhere(
          (opener) => opener.char == run.char && opener.remaining >= used,
        );
        if (index == -1) break;
        final opener = openers[index];
        final openEnd = opener.start + opener.remaining;
        formats.add(
          _InlineFormat(
            offset + openEnd - used,
            offset + openEnd,
            offset + closeStart,
            offset + closeStart + used,
            format,
          ),
        );
        opener.remaining -= used;
        remaining -= used;
        closeStart += used;
        // Las aperturas que quedaron dentro sin cerrar ya no se pueden usar
        unmatched.addAll(openers.sublist(index + 1));
        openers.removeRange(index + 1, openers.length);
        if (opener.remaining < used) {
          unmatched.add(openers.removeAt(index));
        }
      }
      if (remaining > 0) {
        openers.add(_Delimiter(run.char, closeStart, remaining, run.length));
      }
    }

    // Un par sin texto (****, __, ~~~~), recién puesto con la barra, se oculta
    for (final delimiter in [...unmatched, ...openers]) {
      final pairLength = _formatsByChar[delimiter.char]!.marker.length * 2;
      final isWholeRun = delimiter.remaining == delimiter.runLength;
      if (isWholeRun && delimiter.remaining == pairLength) {
        final start = offset + delimiter.start;
        final middle = start + pairLength ~/ 2;
        formats.add(
          _InlineFormat(start, middle, middle, start + pairLength, null),
        );
      }
    }
  }

  static final _formatsByChar = {
    for (final format in MarkdownFormat.values) format.marker[0]: format,
  };

  /// Secuencias seguidas del mismo carácter de marca
  List<({String char, int start, int length})> _delimiterRuns(String line) {
    final runs = <({String char, int start, int length})>[];
    var index = 0;
    while (index < line.length) {
      final char = line[index];
      if (!_formatsByChar.containsKey(char)) {
        index++;
        continue;
      }
      var end = index;
      while (end < line.length && line[end] == char) {
        end++;
      }
      runs.add((char: char, start: index, length: end - index));
      index = end;
    }
    return runs;
  }

  bool _isSpace(String char) => char.trim().isEmpty;

  //#endregion Parseo
}

class _StyledRange {
  final int start;
  final int end;
  final TextStyle style;

  const _StyledRange(this.start, this.end, this.style);
}

enum MarkdownFormat {
  bold(MarkdownConstants.bold, TextStyle(fontWeight: FontWeight.bold)),
  italic(MarkdownConstants.italic, TextStyle(fontStyle: FontStyle.italic)),
  strikethrough(
    MarkdownConstants.strikethrough,
    TextStyle(decoration: TextDecoration.lineThrough),
  );

  final String marker;
  final TextStyle style;

  const MarkdownFormat(this.marker, this.style);
}

/// Un formato encontrado en el texto: marcas en [start, innerStart) y
/// [innerEnd, end), contenido en medio. [type] es null en un par vacío
class _InlineFormat {
  final int start;
  final int innerStart;
  final int innerEnd;
  final int end;
  final MarkdownFormat? type;

  const _InlineFormat(
    this.start,
    this.innerStart,
    this.innerEnd,
    this.end,
    this.type,
  );
}

/// Una apertura pendiente: [remaining] marcas sin usar desde [start]
class _Delimiter {
  final String char;
  final int start;
  final int runLength;
  int remaining;

  _Delimiter(this.char, this.start, this.remaining, this.runLength);
}
