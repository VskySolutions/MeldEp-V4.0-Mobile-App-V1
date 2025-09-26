import 'package:flutter/material.dart';

class ActivityStatusFieldDropdown extends StatefulWidget {
  final List<Map<String, String>> items;
  final String currentId;
  final String currentName;
  final bool disableOpen;
  final ValueChanged<String> onChanged;

  // Optional UI/behavior knobs
  final String? labelText;
  final String? hintText;
  final bool isDense;
  final bool enabled;

  /// If provided, when this focus node gets focus the dropdown menu will open.
  final FocusNode? followingFocusNode;

  /// Whether to open when the following focus node is focused (default true).
  final bool openOnFollowingFocus;

  const ActivityStatusFieldDropdown({
    Key? key,
    required this.items,
    required this.currentId,
    required this.currentName,
    this.disableOpen = false,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.isDense = true,
    this.enabled = true,
    this.followingFocusNode,
    this.openOnFollowingFocus = true,
  }) : super(key: key);

  @override
  State<ActivityStatusFieldDropdown> createState() =>
      _ActivityStatusFieldDropdownState();
}

class _ActivityStatusFieldDropdownState
    extends State<ActivityStatusFieldDropdown> {
  final GlobalKey _fieldKey = GlobalKey();
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = _resolveInitialValue(
      items: widget.items,
      currentId: widget.currentId,
      currentName: widget.currentName,
    );

    // Listen to following focus node to open menu when it gets focus.
    if (widget.followingFocusNode != null && widget.openOnFollowingFocus) {
      widget.followingFocusNode!.addListener(_followingFocusListener);
    }
  }

  @override
  void didUpdateWidget(covariant ActivityStatusFieldDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incomingPropsChanged = oldWidget.currentId != widget.currentId ||
        oldWidget.currentName != widget.currentName ||
        !identical(oldWidget.items, widget.items);

    if (incomingPropsChanged) {
      final newInitial = _resolveInitialValue(
        items: widget.items,
        currentId: widget.currentId,
        currentName: widget.currentName,
      );
      // Only override local selection if parent provides a valid non-empty id.
      if (newInitial != null &&
          newInitial.isNotEmpty &&
          newInitial != _selectedId) {
        setState(() {
          _selectedId = newInitial;
        });
      }
    }

    if (oldWidget.followingFocusNode != widget.followingFocusNode) {
      oldWidget.followingFocusNode?.removeListener(_followingFocusListener);
      widget.followingFocusNode?.addListener(_followingFocusListener);
    }
  }

  Future<void> _showMenu() async {
    if (!mounted) return;
    if (widget.items.isEmpty) return;

    final RenderBox fieldBox =
        _fieldKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context)!.context.findRenderObject() as RenderBox;

    final Offset offset =
        fieldBox.localToGlobal(Offset.zero, ancestor: overlay);
    final Size size = fieldBox.size;
    final double screenWidth = overlay.size.width;

    final double desiredWidth = screenWidth * 0.9;
    final double left = (screenWidth - desiredWidth) / 2;
    final double right = left;

    final RelativeRect position = RelativeRect.fromLTRB(
      left,
      offset.dy + size.height,
      right,
      0,
    );

    final items = widget.items.map((m) {
      final id = (m['id'] ?? '').trim();
      final name = (m['name'] ?? '').trim();
      final isOpen = name.toLowerCase() == 'open';
      final enabled = !(widget.disableOpen && isOpen);

      return PopupMenuItem<String>(
        // Don’t return empty values; only non-empty ids participate in selection.
        value: (enabled && id.isNotEmpty) ? id : null,
        enabled: enabled,
        child: SizedBox(
          width: desiredWidth,
          child: Opacity(
            opacity: (widget.disableOpen && isOpen) ? 0.5 : 1.0,
            child: Text(name),
          ),
        ),
      );
    }).toList();

    final selected = await showMenu<String>(
      context: context,
      position: position,
      items: items,
      initialValue: _selectedId, // highlight current selection
      constraints: BoxConstraints.tightFor(width: desiredWidth),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );

    if (!mounted) return;

    if (selected != null && selected != _selectedId) {
      setState(() {
        _selectedId = selected;
      });
      widget.onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final noItems = widget.items.isEmpty;
    final displayName = _lookupNameById(widget.items, _selectedId ?? '') ??
        (widget.hintText ?? '');

    final isEmpty = displayName.isEmpty;

    return GestureDetector(
      onTap: widget.enabled && !noItems ? _showMenu : null,
      child: InputDecorator(
        key: _fieldKey,
        isFocused: false,
        // Drive emptiness from the resolved display text.
        isEmpty: isEmpty,
        decoration: InputDecoration(
          isDense: widget.isDense,
          labelText: widget.labelText,
          hintText: widget.hintText,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          suffixIcon: Icon(
            Icons.keyboard_arrow_down,
            color: widget.enabled ? null : Theme.of(context).disabledColor,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(
                  color:
                      widget.enabled ? null : Theme.of(context).disabledColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.followingFocusNode?.removeListener(_followingFocusListener);
    super.dispose();
  }

  void _followingFocusListener() {
    if (widget.followingFocusNode!.hasFocus && widget.enabled) {
      // Delay to allow focus animation / keyboard to settle
      // (small microtask ensures layout is ready)
      Future.microtask(() => _showMenu());
    }
  }
}

/// Utility to resolve initial value (same as your original helper)
String? _resolveInitialValue({
  required List<Map<String, String>> items,
  required String currentId,
  required String currentName,
}) {
  if (currentId.isNotEmpty && items.any((m) => (m['id'] ?? '') == currentId)) {
    return currentId;
  }
  if (currentName.isNotEmpty) {
    for (final m in items) {
      final name = (m['name'] ?? '').trim();
      if (name == currentName.trim()) {
        return m['id'];
      }
    }
  }
  return null;
}

String? _lookupNameById(List<Map<String, String>> items, String id) {
  for (final m in items) {
    if ((m['id'] ?? '') == id) return m['name'];
  }
  return null;
}
