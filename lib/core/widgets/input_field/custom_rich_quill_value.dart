import 'dart:async';
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
  QuillController? _controller;
  StreamSubscription<dynamic>? _docSub;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _scrollController = ScrollController();

    // initialize controller from initialHtml (may be null/empty)
    _initControllerFromHtml(widget.initialHtml);
  }

  void _initControllerFromHtml(String? html) {
    // create Document from HTML (or empty Document)
    final Document doc = () {
      if (html != null && html.trim().isNotEmpty) {
        final delta = HtmlToDelta().convert(html);
        return Document.fromDelta(delta);
      }
      return Document();
    }();

    // cancel old subscription and dispose old controller
    _docSub?.cancel();
    _controller?.dispose();

    // create controller
    _controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
      config: const QuillControllerConfig(),
    );

    // listen for document changes and emit HTML
    _docSub = _controller!.document.changes.listen((_) {
      final deltaJson = _controller!.document.toDelta().toJson();
      final html = QuillDeltaToHtmlConverter(
        List.castFrom(deltaJson),
        ConverterOptions.forEmail(),
      ).convert();
      widget.onChanged?.call(html);
    });

    // ensure UI updates to use the new controller
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant HtmlEmailEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If initialHtml changed, recreate the document/controller
    final oldHtml = oldWidget.initialHtml ?? '';
    final newHtml = widget.initialHtml ?? '';
    if (newHtml != oldHtml) {
      _initControllerFromHtml(newHtml);
    }
  }

  @override
  void dispose() {
    _docSub?.cancel();
    _controller?.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If controller not yet ready, show a small placeholder
    final controller = _controller;
    if (controller == null) {
      return SizedBox(
        height: widget.editorHeight,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuillSimpleToolbar(
          controller: controller,
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
            controller: controller,
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
