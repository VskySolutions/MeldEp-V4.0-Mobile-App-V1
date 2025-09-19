import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class CustomTypeAheadField extends StatefulWidget {
  final List<Map<String, String>> items;
  final String? selectedId;
  final String label;
  final Function(String?) onChanged;
  final bool enabled;
  final bool isLoading;
  final String noItemsFoundText;
  final EdgeInsetsGeometry? contentPadding;
  final InputBorder? border;
  final TextStyle? textStyle;
  final VoidCallback? onCleared;

  const CustomTypeAheadField({
    Key? key,
    required this.items,
    required this.selectedId,
    required this.label,
    required this.onChanged,
    this.enabled = true,
    this.isLoading = false,
    this.noItemsFoundText = 'No items found',
    this.contentPadding,
    this.border,
    this.textStyle,
    this.onCleared,
  }) : super(key: key);

  @override
  State<CustomTypeAheadField> createState() => _CustomTypeAheadFieldState();
}

class _CustomTypeAheadFieldState extends State<CustomTypeAheadField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _getInitialText());
    _focusNode = FocusNode()..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(CustomTypeAheadField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId ||
        oldWidget.items != widget.items) {
      _controller.text = _getInitialText();
      setState(() {});
    }
  }

  String _getInitialText() {
    return widget.items.firstWhere(
          (item) => item['id'] == widget.selectedId,
          orElse: () => {'id': '', 'name': ''},
        )['name'] ??
        '';
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TypeAheadField<Map<String, String>>(
        suggestionsCallback: (pattern) async {
          if (!widget.enabled) return <Map<String, String>>[];
          if (widget.isLoading) return null; // trigger loadingBuilder
          final lower = pattern.toLowerCase();
          if (pattern.isEmpty) return widget.items;
          return widget.items
              .where(
                (item) => (item['name'] ?? '').toLowerCase().contains(lower),
              )
              .toList();
        },
        itemBuilder: (context, Map<String, String> suggestion) {
          return ListTile(
            title: Text(suggestion['name'] ?? '', style: widget.textStyle),
          );
        },
        onSelected: (Map<String, String> suggestion) {
          _controller.text = suggestion['name'] ?? '';
          widget.onChanged(suggestion['id']);
          _focusNode.unfocus();
          setState(() {});
        },
        builder: (
          context,
          TextEditingController fieldController,
          FocusNode fieldFocusNode,
        ) {
          final showClear = fieldController.text.isNotEmpty && widget.enabled;
          return TextField(
            controller: fieldController,
            focusNode: fieldFocusNode,
            enabled: widget.enabled, // stays enabled even when loading
            style: widget.textStyle,
            decoration: InputDecoration(
              labelText: widget.label,
              labelStyle: TextStyle(
                color: Colors.black.withOpacity(0.5),
              ),
              border: widget.border ?? const OutlineInputBorder(),
              isDense: true,
              contentPadding: widget.contentPadding ??
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showClear)
                    IconButton(
                      iconSize: 18,
                      padding: const EdgeInsets.all(0),
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        fieldController.clear();
                        widget.onChanged(null);
                        widget.onCleared?.call();
                        fieldFocusNode.requestFocus();
                        setState(() {});
                      },
                    ),
                  IconButton(
                    iconSize: 18,
                    padding: const EdgeInsets.all(0),
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      fieldFocusNode.hasFocus
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down,
                    ),
                    onPressed: widget.enabled
                        ? () {
                            if (fieldFocusNode.hasFocus) {
                              fieldFocusNode.unfocus();
                            } else {
                              fieldFocusNode.requestFocus();
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ),
          );
        },
        controller: _controller,
        hideOnLoading: false, // show dropdown while loading
        loadingBuilder: (context) => const Padding(
          padding: EdgeInsets.all(12.0),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        emptyBuilder: (context) {
          if (widget.isLoading) {
            return const Padding(
              padding: EdgeInsets.all(12.0),
              child: Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(widget.noItemsFoundText),
          );
        },

        constraints: const BoxConstraints(maxHeight: 300),
      ),
    );
  }
}
