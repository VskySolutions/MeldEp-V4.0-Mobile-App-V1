import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

class HtmlEmailEditor extends StatefulWidget {
  final String? initialHtml;
  final ValueChanged<String>? onChanged;
  final double editorHeight;

  const HtmlEmailEditor({
    super.key,
    this.initialHtml,
    this.onChanged,
    this.editorHeight = 160,
  });

  @override
  State<HtmlEmailEditor> createState() => _HtmlEmailEditorState();
}

class _HtmlEmailEditorState extends State<HtmlEmailEditor> {
  late final QuillController _controller;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _scrollController = ScrollController();

    // Build Document from initialHtml if provided
    final Document doc = () {
      final html = widget.initialHtml;
      if (html != null && html.trim().isNotEmpty) {
        final delta = HtmlToDelta().convert(html);
        return Document.fromDelta(delta);
      }
      return Document();
    }();

    _controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
      config: const QuillControllerConfig(),
    );

    // Emit HTML on changes (Delta -> HTML)
    _controller.document.changes.listen((_) {
      final deltaJson = _controller.document.toDelta().toJson();
      final html = QuillDeltaToHtmlConverter(
        List.castFrom(deltaJson),
        ConverterOptions.forEmail(),
      ).convert();
      widget.onChanged?.call(html);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuillSimpleToolbar(
          controller: _controller,
          config: const QuillSimpleToolbarConfig(
            multiRowsDisplay: false,
            showDividers: false,
            showBoldButton: true,
            showItalicButton: true,
            showStrikeThrough: true,
            showListBullets: true,
            showListNumbers: true,
            showLink: true,
            showUndo: true,
            showRedo: true,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: widget.editorHeight,
          child: QuillEditor.basic(
            controller: _controller,
            focusNode: _focusNode,
            scrollController: _scrollController,
            config: const QuillEditorConfig(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              maxContentWidth: 800,
            ),
          ),
        ),
      ],
    );
  }
}
