// Replace your file with this full contents
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

class HtmlEditorInputField extends StatefulWidget {
  final String? initialHtml;
  final ValueChanged<String>? onChanged;
  final double editorHeight;
  final bool showLessOptions;

  const HtmlEditorInputField({
    super.key,
    this.initialHtml,
    this.onChanged,
    this.editorHeight = 160,
    this.showLessOptions = false,
  });

  @override
  State<HtmlEditorInputField> createState() => _HtmlEditorInputFieldState();
}

class _HtmlEditorInputFieldState extends State<HtmlEditorInputField> {
  QuillController? _controller;
  StreamSubscription<dynamic>? _docSub;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;

  // View source toggle: if true we show raw HTML text area instead of editor
  bool _showSource = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _scrollController = ScrollController();
    _initControllerFromHtml(widget.initialHtml);
  }

  void _initControllerFromHtml(String? html) {
    // Build document from HTML or empty
    final Document doc = () {
      if (html != null && html.trim().isNotEmpty) {
        final delta = HtmlToDelta().convert(html);
        return Document.fromDelta(delta);
      }
      return Document();
    }();

    // Cleanup previous
    _docSub?.cancel();
    _controller?.dispose();

    // Create controller
    _controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
      config: const QuillControllerConfig(),
    );

    // Listen for document changes and emit HTML
    _docSub = _controller!.document.changes.listen((_) {
      final d = _controller!.document;
      final String plain = d.toPlainText();
      final String normalized =
          plain.replaceAll(RegExp(r'[\s\u00A0\u200B]+'), '');
      if (normalized.isEmpty) {
        widget.onChanged?.call('');
        return;
      }
      final deltaJson = d.toDelta().toJson();
      final html = QuillDeltaToHtmlConverter(
        List.castFrom(deltaJson),
        ConverterOptions.forEmail(),
      ).convert();
      widget.onChanged?.call(html);
    });

    setState(() {});
  }

  @override
  void didUpdateWidget(covariant HtmlEditorInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  // helper: toggle inline or block attribute
  void _toggleAttribute(Attribute attr) {
    if (_controller == null) return;
    final current = _controller!.getSelectionStyle().attributes;
    final isActive = current.containsKey(attr.key);
    final toSet = isActive ? Attribute.clone(attr, null) : attr;
    _controller!.formatSelection(toSet);
  }

  // Helper: apply alignment
  void _applyAlignment(Attribute alignmentAttr) {
    if (_controller == null) return;
    _controller!.formatSelection(alignmentAttr);
  }

  // Helper: apply list (bullet or ordered)
  void _applyList(Attribute listAttr) {
    if (_controller == null) return;
    final current = _controller!.getSelectionStyle().attributes;
    final isActive = current.containsKey(Attribute.list.key) &&
        current[Attribute.list.key]!.value == listAttr.value;
    final toSet = isActive ? Attribute.clone(Attribute.list, null) : listAttr;
    _controller!.formatSelection(toSet);
  }

  // Helper: indent increase/decrease
  void _changeIndent(bool increase) {
    if (_controller == null) return;
    final attrs = _controller!.getSelectionStyle().attributes;
    final indentAttr = attrs[Attribute.indent.key];
    int level = 0;
    if (indentAttr != null) {
      final v = indentAttr.value;
      if (v is int) level = v;
      else {
        // try parse
        level = int.tryParse(v.toString()) ?? 0;
      }
    }
    final newLevel = (increase ? (level + 1) : (level - 1)).clamp(0, 10);
    if (newLevel <= 0) {
      _controller!.formatSelection(Attribute.clone(Attribute.indent, null));
    } else {
      _controller!.formatSelection(Attribute.getIndentLevel(newLevel));
    }
  }

  // Insert "horizontal rule" fallback: insert a thin dashed line as text block
  void _insertHorizontalRule() {
    if (_controller == null) return;
    final sel = _controller!.selection;
    final index = sel.baseOffset;
    // Insert a simple visual rule; if you want a true embed you'd need to register a BlockEmbed
    final ruleText = '\n\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n';
    _controller!.replaceText(index, 0, ruleText, TextSelection.collapsed(offset: index + ruleText.length));
  }

  // Insert or edit hyperlink
  Future<void> _insertLink() async {
    if (_controller == null) return;
    final sel = _controller!.selection;
    // Ask for URL
    final TextEditingController urlController = TextEditingController();
    final link = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Insert link'),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(hintText: 'https://example.com'),
            keyboardType: TextInputType.url,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(urlController.text.trim()), child: const Text('Insert')),
          ],
        );
      },
    );

    if (link == null || link.isEmpty) return;
    final uri = link;

    if (sel.isCollapsed) {
      // If nothing selected -> insert the url text and apply link
      final index = sel.baseOffset;
      _controller!.replaceText(index, 0, uri, TextSelection(baseOffset: index, extentOffset: index + uri.length));
      _controller!.formatSelection(Attribute.fromKeyValue('link', uri));
      // move cursor after inserted link
      _controller!.updateSelection(TextSelection.collapsed(offset: index + uri.length), ChangeSource.local);
    } else {
      // apply link to selected text
      _controller!.formatSelection(Attribute.fromKeyValue('link', uri));
    }
  }

  // Remove formatting for a selection (basic set)
  void _removeFormatting() {
    if (_controller == null) return;
    final inlineAttrs = <Attribute>[
      Attribute.bold,
      Attribute.italic,
      Attribute.underline,
      Attribute.strikeThrough,
      Attribute.inlineCode,
      Attribute.color,
      Attribute.background,
      Attribute.font,
      Attribute.size,
    ];
    for (final a in inlineAttrs) {
      _controller!.formatSelection(Attribute.clone(a, null));
    }
    // Clear link
    _controller!.formatSelection(Attribute.clone(Attribute.link, null));
  }

  // Convert current document to HTML string (used for view source)
  String _currentDocumentHtml() {
    if (_controller == null) return '';
    final deltaJson = _controller!.document.toDelta().toJson();
    final html = QuillDeltaToHtmlConverter(
      List.castFrom(deltaJson),
      ConverterOptions.forEmail(),
    ).convert();
    return html;
  }

  // Build small toggle icon for inline attributes
  Widget _buildToggleButton({
    required Widget icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool toggled = false,
  }) {
    final color = toggled ? Theme.of(context).colorScheme.primary : null;
    return IconButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed,
      color: color,
      splashRadius: 20,
    );
  }

  // Build toolbar content according to showLessOptions flag
  Widget _buildToolbar(QuillController controller) {
    final selectionAttrs = controller.getSelectionStyle().attributes;
    final isBold = selectionAttrs.containsKey(Attribute.bold.key);
    final isItalic = selectionAttrs.containsKey(Attribute.italic.key);
    final isStrike = selectionAttrs.containsKey(Attribute.strikeThrough.key);
    final isUnderline = selectionAttrs.containsKey(Attribute.underline.key);
    final listAttr = selectionAttrs[Attribute.list.key];
    final isBullet = listAttr != null && listAttr.value == Attribute.ul.value;
    final isNumber = listAttr != null && listAttr.value == Attribute.ol.value;

    // alignment active detection (left/center/right/justify)
    final alignAttr = selectionAttrs[Attribute.align.key];
    final alignedLeft = alignAttr == null || alignAttr.value == Attribute.leftAlignment.value;
    final alignedCenter = alignAttr != null && alignAttr.value == Attribute.centerAlignment.value;
    final alignedRight = alignAttr != null && alignAttr.value == Attribute.rightAlignment.value;
    final alignedJustify = alignAttr != null && alignAttr.value == Attribute.justifyAlignment.value;

    // Common minimal buttons (show in both modes)
    final List<Widget> baseButtons = [
      // Align dropdown
      PopupMenuButton<Attribute>(
        tooltip: 'Align',
        onSelected: (val) => _applyAlignment(val),
        itemBuilder: (_) => [
          const PopupMenuItem(value: Attribute.leftAlignment, child: Text('Left')),
          const PopupMenuItem(value: Attribute.centerAlignment, child: Text('Center')),
          const PopupMenuItem(value: Attribute.rightAlignment, child: Text('Right')),
          const PopupMenuItem(value: Attribute.justifyAlignment, child: Text('Justify')),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(
            Icons.format_align_left,
            size: 20,
            color: (alignedCenter || alignedRight || alignedJustify) ? null : Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      // Bold
      _buildToggleButton(
        icon: const Icon(Icons.format_bold),
        tooltip: 'Bold',
        onPressed: () => _toggleAttribute(Attribute.bold),
        toggled: isBold,
      ),
      // Italic
      _buildToggleButton(
        icon: const Icon(Icons.format_italic),
        tooltip: 'Italic',
        onPressed: () => _toggleAttribute(Attribute.italic),
        toggled: isItalic,
      ),
      // Strikethrough
      _buildToggleButton(
        icon: const Icon(Icons.strikethrough_s),
        tooltip: 'Strikethrough',
        onPressed: () => _toggleAttribute(Attribute.strikeThrough),
        toggled: isStrike,
      ),
      // Underline
      _buildToggleButton(
        icon: const Icon(Icons.format_underlined),
        tooltip: 'Underline',
        onPressed: () => _toggleAttribute(Attribute.underline),
        toggled: isUnderline,
      ),
      // Bullets
      _buildToggleButton(
        icon: const Icon(Icons.format_list_bulleted),
        tooltip: 'Bulleted list',
        onPressed: () => _applyList(Attribute.ul),
        toggled: isBullet,
      ),
      // Numbers
      _buildToggleButton(
        icon: const Icon(Icons.format_list_numbered),
        tooltip: 'Numbered list',
        onPressed: () => _applyList(Attribute.ol),
        toggled: isNumber,
      ),
    ];

    if (widget.showLessOptions) {
      // Return minimal toolbar row
      return Row(children: baseButtons);
    }

    // Full toolbar additions
    final List<Widget> extraButtons = [
      // Insert horizontal rule
      IconButton(
        icon: const Icon(Icons.horizontal_rule),
        tooltip: 'Insert horizontal rule',
        onPressed: _insertHorizontalRule,
        splashRadius: 20,
      ),
      // Hyperlink
      IconButton(
        icon: const Icon(Icons.link),
        tooltip: 'Insert link',
        onPressed: _insertLink,
        splashRadius: 20,
      ),
      // Inline code / formatting toggle
      _buildToggleButton(
        icon: const Icon(Icons.code),
        tooltip: 'Inline code',
        onPressed: () => _toggleAttribute(Attribute.inlineCode),
        toggled: selectionAttrs.containsKey(Attribute.inlineCode.key),
      ),
      // Remove formatting
      IconButton(
        icon: const Icon(Icons.format_clear),
        tooltip: 'Remove formatting',
        onPressed: _removeFormatting,
        splashRadius: 20,
      ),
      // Quote
      _buildToggleButton(
        icon: const Icon(Icons.format_quote),
        tooltip: 'Quote',
        onPressed: () => _toggleAttribute(Attribute.blockQuote),
        toggled: selectionAttrs.containsKey(Attribute.blockQuote.key),
      ),
      // Decrease indent
      IconButton(
        icon: const Icon(Icons.format_indent_decrease),
        tooltip: 'Decrease indent',
        onPressed: () => _changeIndent(false),
        splashRadius: 20,
      ),
      // Increase indent
      IconButton(
        icon: const Icon(Icons.format_indent_increase),
        tooltip: 'Increase indent',
        onPressed: () => _changeIndent(true),
        splashRadius: 20,
      ),
      // Undo
      IconButton(
        icon: const Icon(Icons.undo),
        tooltip: 'Undo',
        onPressed: () => _controller?.undo(),
        splashRadius: 20,
      ),
      // Redo
      IconButton(
        icon: const Icon(Icons.redo),
        tooltip: 'Redo',
        onPressed: () => _controller?.redo(),
        splashRadius: 20,
      ),
      // View source (raw HTML)
      IconButton(
        icon: Icon(_showSource ? Icons.visibility_off : Icons.visibility),
        tooltip: _showSource ? 'Hide source' : 'View HTML source',
        onPressed: () => setState(() => _showSource = !_showSource),
        splashRadius: 20,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [...baseButtons, const SizedBox(width: 8), ...extraButtons]),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        // Toolbar
        Material(
          elevation: 0,
          color: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: _buildToolbar(controller),
          ),
        ),
        const SizedBox(height: 6),
        // Editor or source view
        SizedBox(
          height: widget.editorHeight,
          child: _showSource
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextFormField(
                    initialValue: _currentDocumentHtml(),
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    onChanged: (val) {
                      // If user edits HTML source, try convert back to delta after a short validation step.
                      // For simplicity we call _initControllerFromHtml directly (may throw if invalid HTML).
                      // In production you might want to validate or disable editing here.
                      _initControllerFromHtml(val);
                    },
                  ),
                )
              : QuillEditor.basic(
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
