import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CustomTypeAheadField extends StatefulWidget {
  final List<Map<String, String>> items;
  final String? selectedId;
  final String? selectedValue;
  final String label;
  final Function(String?) onChanged;
  final bool enabled;
  final bool isLoading;
  final String noItemsFoundText;
  final EdgeInsetsGeometry? contentPadding;
  final InputBorder? border;
  final TextStyle? textStyle;
  final VoidCallback? onCleared;
  final String? errorText;
  final SuggestionsController<Map<String, String>>? suggestionsController;
  final Future<void> Function()? onOpen;
  final void Function(Map<String, String>? item)? onSelectedItem;
  final bool propagateOnClear;
  final String? moreInfoDesc;

  const CustomTypeAheadField({
    Key? key,
    required this.items,
    required this.selectedId,
    this.selectedValue,
    required this.label,
    required this.onChanged,
    this.enabled = true,
    this.isLoading = false,
    this.noItemsFoundText = 'No items found',
    this.contentPadding,
    this.border,
    this.textStyle,
    this.onCleared,
    this.errorText,
    this.suggestionsController,
    this.onOpen,
    this.onSelectedItem,
    this.propagateOnClear = true,
    this.moreInfoDesc,
  }) : super(key: key);

  @override
  State<CustomTypeAheadField> createState() => _CustomTypeAheadFieldState();
}

class _CustomTypeAheadFieldState extends State<CustomTypeAheadField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final SuggestionsController<Map<String, String>> _sugCtrl;
  bool _typedSinceFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _getInitialText());
    _sugCtrl = widget.suggestionsController ??
        SuggestionsController<Map<String, String>>();
    _focusNode = FocusNode()
      ..addListener(() {
        if (_focusNode.hasFocus) {
          _typedSinceFocus = false;
          final fut = widget.onOpen?.call();
          if (fut == null) {
            _sugCtrl.open();
            _sugCtrl.refresh();
          } else {
            fut.whenComplete(() {
              if (mounted) {
                _sugCtrl.open();
                _sugCtrl.refresh();
              }
            });
          }
        }
        setState(() {});
      });
  }

  @override
  void didUpdateWidget(CustomTypeAheadField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final itemsChanged = !_sameItems(oldWidget.items, widget.items);
    final selectionChanged = oldWidget.selectedId != widget.selectedId;
    if (itemsChanged || selectionChanged) {
      _controller.text = _getInitialText();
      _typedSinceFocus = false;
      _sugCtrl.refresh();
      setState(() {});
    }
  }

  bool _sameItems(List<Map<String, String>> a, List<Map<String, String>> b) {
    final aa = a.map((e) => '${e['id']}|${e['name']}').toList();
    final bb = b.map((e) => '${e['id']}|${e['name']}').toList();
    return listEquals(aa, bb);
  }

  String _getInitialText() {
    return widget.items.firstWhere(
          (item) => item['id'] == widget.selectedId,
          orElse: () => {
            'id': widget.selectedId ?? "",
            'name': widget.selectedValue ?? ""
          },
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
        showOnFocus: true,
        suggestionsController: _sugCtrl,
        suggestionsCallback: (pattern) async {
          if (!widget.enabled) return <Map<String, String>>[];
          if (widget.isLoading) return null;

          int _cmp(Map<String, String> a, Map<String, String> b) {
            final na = (a['name'] ?? '').toLowerCase();
            final nb = (b['name'] ?? '').toLowerCase();
            return na.compareTo(nb);
          }

          if (!_typedSinceFocus || pattern.isEmpty) {
            final all = List<Map<String, String>>.from(widget.items);
            all.sort(_cmp);
            return all;
          }

          final lower = pattern.toLowerCase();
          final filtered = widget.items
              .where((it) => (it['name'] ?? '').toLowerCase().contains(lower))
              .toList();
          filtered.sort(_cmp);
          return filtered;
        },
        itemBuilder: (context, Map<String, String> suggestion) {
          final description = suggestion['description'] ?? "";
          return ListTile(
            title: Row(
              children: [
                Expanded(
                  child:
                      Text(suggestion['name'] ?? '', style: widget.textStyle),
                ),
                if (description.isNotEmpty)
                  InfoTooltipIcon(description: description),
              ],
            ),
          );
        },
        onSelected: (Map<String, String> suggestion) {
          _controller.text = suggestion['name'] ?? '';
          widget.onSelectedItem?.call(suggestion);
          widget.onChanged(suggestion['id']);
          _typedSinceFocus = false;
          _focusNode.unfocus();
          setState(() {});
        },
        builder: (context, fieldController, fieldFocusNode) {
          // Find selected item's description
          final selectedDescription = (() {
            for (final item in widget.items) {
              if (item['id'] == widget.selectedId) {
                return item['description'] ?? "";
              }
            }
            return "";
          })();

          final showClear = fieldController.text.isNotEmpty && widget.enabled;
          return Stack(
            alignment: Alignment.centerRight,
            children: [
              TextField(
                controller: fieldController,
                focusNode: fieldFocusNode,
                enabled: widget.enabled,
                style: widget.textStyle,
                onChanged: (_) {
                  if (!_typedSinceFocus) {
                    _typedSinceFocus = true;
                    _sugCtrl.refresh();
                  }
                },
                onTap: () {
                  _typedSinceFocus = false;
                  if (!fieldFocusNode.hasFocus && widget.enabled) {
                    fieldFocusNode.requestFocus();
                  } else {
                    fieldFocusNode.unfocus();
                  }
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: widget.label,
                  errorText: widget.errorText,
                  labelStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                  border: widget.border ?? const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showClear)
                        IconButton(
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            fieldController.clear();
                            widget.onSelectedItem?.call(null);
                            if (widget.propagateOnClear) {
                              widget.onChanged(null);
                            }
                            widget.onCleared?.call();
                            _typedSinceFocus = false;
                            // FIXED: Close dropdown and remove focus to prevent it from showing
                            _sugCtrl.close();
                            fieldFocusNode.unfocus();
                            setState(() {});
                          },
                        ),
                      IconButton(
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          fieldFocusNode.hasFocus
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                        ),
                        onPressed: widget.enabled
                            ? () {
                                _typedSinceFocus = false;
                                if (fieldFocusNode.hasFocus) {
                                  // Close dropdown by removing focus
                                  fieldFocusNode.unfocus();
                                } else {
                                  // Open dropdown by requesting focus
                                  fieldFocusNode.requestFocus();
                                }
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              if (selectedDescription.isNotEmpty && !widget.enabled)
                Positioned(
                  right: 50,
                  child: InfoTooltipIcon(description: selectedDescription),
                ),
            ],
          );
        },
        controller: _controller,
        retainOnLoading: false,
        hideOnLoading: false,
        loadingBuilder: (context) => const Padding(
          padding: EdgeInsets.all(12.0),
          child: Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
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
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(widget.noItemsFoundText),
          );
        },
        hideWithKeyboard: false,
        autoFlipDirection: true,
        offset: const Offset(0, 8),
      ),
    );
  }
}

class InfoTooltipIcon extends StatelessWidget {
  final String? description;
  final double size;
  final Color? color;
  final bool preferBelow;

  const InfoTooltipIcon({
    super.key,
    required this.description,
    this.size = 18,
    this.color,
    this.preferBelow = true,
  });

  @override
  Widget build(BuildContext context) {
    final text = (description?.trim().isNotEmpty == true)
        ? description!.trim()
        : 'No description';
    return Tooltip(
      message: text,
      preferBelow: preferBelow,
      triggerMode: TooltipTriggerMode.longPress,
      child: GestureDetector(
        onTap: () => Fluttertoast.showToast(
          msg: "Press and hold to view activity description",
        ),
        child: Icon(
          Icons.info_outline,
          size: size,
          color: color ?? Colors.grey[800],
        ),
      ),
    );
  }
}
