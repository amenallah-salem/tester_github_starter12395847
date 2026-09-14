import 'package:flutter/material.dart';

/// Minimal, dependency-free rendering of the subset of Markdown Kaori's
/// responses actually use: headings, bold, bullet/numbered lists, and
/// paragraphs. Not a full Markdown engine — just enough that AI responses
/// don't show raw '##'/'**' syntax. Tables render as plain monospace rows
/// rather than a real grid, which is an acceptable simplification here.
class MarkdownLiteText extends StatelessWidget {
  const MarkdownLiteText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }
      if (line.startsWith('### ')) {
        widgets.add(_heading(line.substring(4), baseStyle, 15));
      } else if (line.startsWith('## ')) {
        widgets.add(_heading(line.substring(3), baseStyle, 16));
      } else if (line.startsWith('# ')) {
        widgets.add(_heading(line.substring(2), baseStyle, 18));
      } else if (line.trimLeft().startsWith('- ') || line.trimLeft().startsWith('* ')) {
        widgets.add(_bullet(line.trimLeft().substring(2), baseStyle));
      } else if (RegExp(r'^\d+\.\s').hasMatch(line.trimLeft())) {
        widgets.add(_bullet(
          line.trimLeft().replaceFirst(RegExp(r'^\d+\.\s'), ''),
          baseStyle,
          marker: '${line.trimLeft().split('.').first}.',
        ));
      } else if (line.trim() == '---') {
        widgets.add(const Divider(height: 20));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _richInline(line, baseStyle),
        ));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: widgets);
  }

  Widget _heading(String text, TextStyle base, double size) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: _richInline(text, base.copyWith(fontSize: size, fontWeight: FontWeight.w700)),
    );
  }

  Widget _bullet(String text, TextStyle base, {String marker = '•'}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 20, child: Text(marker, style: base)),
          Expanded(child: _richInline(text, base)),
        ],
      ),
    );
  }

  /// Renders `**bold**` spans inline within otherwise-plain text.
  Widget _richInline(String text, TextStyle base) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    var last = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start), style: base));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: base.copyWith(fontWeight: FontWeight.w700),
      ));
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: base));
    }
    return RichText(text: TextSpan(children: spans, style: base));
  }
}
