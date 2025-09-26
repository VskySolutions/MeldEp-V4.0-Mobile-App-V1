import 'package:flutter/material.dart';

// Square, lightly-rounded status pill dropdown that opens via showMenu
Widget BuildActivityStatusPillDropdown({
  required BuildContext context, // build context
  required String currentId, // currently selected id
  required String currentName, // label to show in pill
  required bool disableOpen, // disable "Open" item
  required List<Map<String, String>> items, // [{'id':'...','name':'...'}]
  required ValueChanged<String> onChanged, // returns new id
}) {
  // Resolve display text and colors
  final String displayName = currentName.isNotEmpty
      ? currentName
      : (_lookupNameById(items, currentId) ?? '--');
  final _StatusColors colors = _statusColorsFor(displayName);

  // Guard: avoid showMenu assertion if items are empty
  Future<void> _openMenu(TapDownDetails details) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No statuses available')),
      );
      return;
    }

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        MediaQuery.of(context).size.width - details.globalPosition.dx,
        MediaQuery.of(context).size.height - details.globalPosition.dy,
      ),
      items: items.map((m) {
        final String id = m['id'] ?? '';
        final String name = m['name'] ?? '';
        final bool isOpenLabel = name.trim().toLowerCase() == 'open';
        final bool isDisabled = disableOpen && isOpenLabel;
        return PopupMenuItem<String>(
          value: id,
          enabled: !isDisabled,
          child: Text(
            name,
            style: TextStyle(
              fontSize: 13,
              color: isDisabled ? Colors.black.withOpacity(0.35) : Colors.black,
            ),
          ),
        );
      }).toList(),
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );

    // No selection
    if (selected == null) return;

    // Do not fire if selecting the same id
    if (selected == currentId) return;

    // Prevent choosing "Open" when disabled (extra guard)
    final String selectedName = _lookupNameById(items, selected) ?? '';
    final bool selectedIsOpen = selectedName.trim().toLowerCase() == 'open';
    if (disableOpen && selectedIsOpen) return;

    // Return selected id
    onChanged(selected);
  }

  return GestureDetector(
    behavior: HitTestBehavior.translucent, // ensure taps are captured
    onTapDown: _openMenu,
    child: Container(
      constraints:
          const BoxConstraints(minHeight: 28), // compact, square-ish height
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.fill,
        border: Border.all(color: colors.border, width: 1),
        borderRadius: BorderRadius.circular(6), // square with slight round
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down,
              size: 16, color: Colors.black87),
        ],
      ),
    ),
  );
}

// ——— Helpers and colors ———

class _StatusColors {
  final Color border;
  final Color fill;
  const _StatusColors(this.border, this.fill);
}

_StatusColors _statusColorsFor(String statusName) {
  final s = statusName.trim().toLowerCase();
  if (s.startsWith('new')) {
    return const _StatusColors(Color(0xFF1B75AB), Color.fromARGB(255, 153, 204, 245));
  }
  if (s == 'open') {
    return const _StatusColors(Color(0xFF800080), Color.fromARGB(255, 213, 162, 223));
  }
  if (s == 'completed') {
    return const _StatusColors(Color(0xFF008000), Color.fromARGB(255, 167, 224, 170));
  }
  // Fallback
  return _StatusColors(Colors.grey.shade400, Colors.grey.shade200);
}

String? _lookupNameById(List<Map<String, String>> items, String id) {
  if (id.isEmpty) return null;
  for (final m in items) {
    if ((m['id'] ?? '') == id) return m['name'];
  }
  return null;
}
