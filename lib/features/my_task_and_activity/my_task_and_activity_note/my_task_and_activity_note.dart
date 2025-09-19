import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:html/parser.dart' as parser;

import 'package:test_project/core/dialogs/delete_confirmation_dialog.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/utils/extensions.dart';
import 'package:test_project/core/widgets/custom_snackbar.dart';
import 'package:test_project/core/widgets/input_field/custom_rich_quill_value.dart';
import 'package:test_project/features/my_task_and_activity/my_task_and_activity_service.dart';

class MyTaskAndActivityNoteScreen extends StatefulWidget {
  const MyTaskAndActivityNoteScreen({super.key, required this.id});

  /// Project activity identifier for which notes are managed.
  final String id;

  @override
  State<MyTaskAndActivityNoteScreen> createState() => _MyTaskAndActivityNoteScreenState();
}

class _MyTaskAndActivityNoteScreenState extends State<MyTaskAndActivityNoteScreen> {
  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Variable Declarations
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  List<TaskNoteDetailsModel> _noteDetails = <TaskNoteDetailsModel>[];
  bool _isLoading = true;
  bool _isSubmitting = false;

  String? _noteId; // If set, update existing note; otherwise create new.

  // Controllers
  final TextEditingController _noteFieldController = TextEditingController();

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Lifecycle
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Initializes the screen by loading existing notes.
  @override
  void initState() {
    super.initState();
    _fetchTaskNoteDetails();
  }

  /// Disposes controllers to free resources.
  @override
  void dispose() {
    _noteFieldController.dispose();
    super.dispose();
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// API Calls & Data Ops
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Loads note details for the current activity id and updates loading flags.
  Future<void> _fetchTaskNoteDetails() async {
    setState(() => _isLoading = true);
    try {
      final response = await MyTaskAndActivityService.instance.getTaskNoteDetails(widget.id);
      if (response.statusCode == 200) {
        setState(() {
          _noteDetails = TaskNoteDetailsModel.listFromJson(response.data as List<dynamic>);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Fetch note details error: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Persists a new or edited note; clears input and refreshes the list on success.
  Future<void> _saveNote(BuildContext context) async {
    if (_noteFieldController.text.trim().isEmpty) {
      showCustomSnackBar(
        context,
        message: 'Add note to continue',
        backgroundColor: AppColors.ERROR,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    Fluttertoast.showToast(
      msg: 'Submitting.... Please wait',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );

    final Map<String, dynamic> payload = <String, dynamic>{
      'id': _noteId,
      'taggedPersonId': '',
      'subModuleId': widget.id,
      'type': 'project Activities',
      'moduleId': '',
      'module': '',
      'sub_Module': '',
      'note': _noteFieldController.text,
    };

    try {
      final response = await MyTaskAndActivityService.instance.postUpdateTaskNote(payload);
      if (response.statusCode == 204) {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
          _noteId = null;
          _noteFieldController.clear();
        });
        showCustomSnackBar(context, message: 'Note added successfully', durationSeconds: 2);
        await _fetchTaskNoteDetails();
      } else {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        showCustomSnackBar(context, message: 'Failed to add note', backgroundColor: AppColors.ERROR);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      debugPrint('Add note error: $e');
      showCustomSnackBar(context, message: 'Error adding note', backgroundColor: AppColors.ERROR);
    }
  }

  /// Deletes a note after backend confirmation and refreshes the list.
  Future<void> _deleteTaskNote(String id, BuildContext context) async {
    try {
      final response = await MyTaskAndActivityService.instance.deleteTaskNote(id);
      if (response.statusCode == 204) {
        showCustomSnackBar(context, message: 'Note deleted successfully');
        await _fetchTaskNoteDetails();
      } else {
        showCustomSnackBar(context, message: 'Failed to delete note', backgroundColor: AppColors.ERROR);
      }
    } catch (e) {
      debugPrint('Delete note error: $e');
      showCustomSnackBar(context, message: 'Error deleting note', backgroundColor: AppColors.ERROR);
    }
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Actions & Event Handlers
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Confirms back navigation; returns true to allow leaving.
  Future<bool> _shouldGoBack(BuildContext context) async {
    return true;
  }

  /// Opens the delete confirmation dialog and triggers deletion if confirmed.
  void _onDeletePressed(TaskNoteDetailsModel note) {
    showDeleteConfirmationDialog(
      context,
      title: 'Delete Confirmation',
      description: 'Are you sure you want to remove this entry permanently?',
      onDelete: () => _deleteTaskNote(note.noteId, context),
    );
  }

  /// Prepares an existing note for editing by loading it into the editor.
  void _onEditPressed(TaskNoteDetailsModel note) {
    print(note.noteId);
    print(note.note);
    setState(() {
      _noteId = note.noteId;
      _noteFieldController.text = note.note;
    });
  }

  /// Validates and saves the current note content.
  void _onSavePressed() {
    if (!_isLoading && !_isSubmitting) {
      _saveNote(context);
    }
  }

  /// Handles back button presses from AppBar and FAB.
  Future<void> _onBackPressed() async {
    final shouldNavigate = await _shouldGoBack(context);
    if (shouldNavigate && mounted) context.pop();
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// UI
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Builds the notes editor and the table of existing notes.
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldNavigate = await _shouldGoBack(context);
        return shouldNavigate ? true : false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _onBackPressed,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          title: const Text(
            'Add/View Notes',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.PRIMARY,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Note',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.PRIMARY,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildNoteEditor(),
                    const SizedBox(height: 24),
                    const Text(
                      'View Notes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.PRIMARY,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildNotesTable(),
                  ],
                ),
              ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Opacity(
              opacity: _isLoading || _isSubmitting ? 0.6 : 1,
              child: SizedBox(
                height: 56,
                width: 56,
                child: FloatingActionButton(
                  onPressed: _onSavePressed,
                  backgroundColor: AppColors.PRIMARY,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Opacity(
              opacity: _isSubmitting ? 0.6 : 1,
              child: SizedBox(
                height: 56,
                width: 56,
                child: FloatingActionButton(
                  onPressed: _isSubmitting ? null : _onBackPressed,
                  heroTag: 'back',
                  backgroundColor: AppColors.PRIMARY,
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Back',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// UI Helpers
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Returns a plain-text preview extracted from HTML, with list awareness and truncation.
  String _parseHtmlPreview(String? htmlString) {
    if (htmlString == null || htmlString.isEmpty) {
      return 'No details available';
    }
    try {
      if (!htmlString.contains('<') || !htmlString.contains('>')) {
        return _truncateText(htmlString, maxLength: 100);
      }
      final document = parser.parse(htmlString);
      final liElements = document.querySelectorAll('li');
      if (liElements.isEmpty) {
        return _truncateText(document.body?.text ?? htmlString, maxLength: 100);
      }
      final firstItemText = _cleanText(liElements.first.text);
      final additionalItems = liElements.length - 1;
      return additionalItems > 0 ? '$firstItemText (+$additionalItems more)' : firstItemText;
    } catch (_) {
      return _truncateText(htmlString, maxLength: 100);
    }
  }

  /// Removes extra whitespace and newlines in a string.
  String _cleanText(String text) {
    return text.trim().replaceAll('\n', ' ').replaceAll(RegExp(r'\s{2,}'), ' ');
  }

  /// Truncates a string to maxLength and appends ellipsis.
  String _truncateText(String text, {required int maxLength}) {
    final cleaned = _cleanText(text);
    if (cleaned.length <= maxLength) return cleaned;
    return '${cleaned.substring(0, maxLength).trim()}...';
  }

  /// Builds the rich text note editor.
  Widget _buildNoteEditor() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Note',
        border: OutlineInputBorder(),
        hintText: 'Enter note',
        isDense: true,
        contentPadding: EdgeInsets.all(8),
      ),
      child: HtmlEmailEditor(
        editorHeight: 140,
        initialHtml: _noteFieldController.text,
        onChanged: (html) => _noteFieldController.text = html,
      ),
    );
  }

  /// Builds a thin vertical divider used between columns.
  Widget _horizontalDivider() => Container(width: 1, color: Colors.black12);

  /// Builds the notes table including header and rows.
  Widget _buildNotesTable() {
    if (_noteDetails.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        child: const Text(
          'No data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.PRIMARY),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: const [
              Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(width: 1),
              Expanded(flex: 2, child: Text('Cr. by', style: TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(width: 1),
              Expanded(flex: 5, child: Text('Note', style: TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(width: 1),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const Divider(),
          // Rows
          ..._noteDetails.map((note) {
            final date = note.createdDate.length >= 8
                ? note.createdDate.substring(0, 6) + note.createdDate.substring(8)
                : note.createdDate;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text(date)),
                  _horizontalDivider(),
                  Expanded(
                    flex: 2,
                    child: Tooltip(
                      message: note.createdBy,
                      preferBelow: true,
                      child: GestureDetector(
                        onTap: () {
                          Fluttertoast.showToast(
                            msg: 'Press and hold to view full name',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                          );
                        },
                        child: Row(
                          children: [
                            Text(note.createdBy.toInitials()),
                            const SizedBox(width: 4),
                            Icon(Icons.info_outline, size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _horizontalDivider(),
                  Expanded(
                    flex: 5,
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            _parseHtmlPreview(note.note),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showDetailsDialog(context, note.note),
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.grey,
                            child: const Icon(Icons.info_outline, size: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _horizontalDivider(),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: () => _onEditPressed(note),
                            child: const SizedBox(
                              height: 25,
                              width: 25,
                              child: Center(
                                child: Icon(Icons.edit, size: 18, color: Colors.black),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: () => _onDeletePressed(note),
                            child: const SizedBox(
                              height: 25,
                              width: 25,
                              child: Center(
                                child: Icon(Icons.delete_outline, size: 18, color: AppColors.ERROR),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Shows full note details in a dialog with HTML rendering.
  void _showDetailsDialog(BuildContext context, String? htmlContent) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Note'),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: (htmlContent != null && htmlContent.isNotEmpty)
            ? SingleChildScrollView(
                child: Html(
                  data: htmlContent,
                  style: {
                    'ul': Style(margin: Margins.zero),
                    'li': Style(margin: Margins.only(bottom: 8), listStylePosition: ListStylePosition.outside),
                    'p': Style(margin: Margins.zero),
                  },
                ),
              )
            : const Text('No details available'),
      ),
    );
  }
}

/// --------------------------------------------------------------------------------------------------------------------------------------------------
/// Model
/// --------------------------------------------------------------------------------------------------------------------------------------------------

/// Minimal note details model used by this screen.
class TaskNoteDetailsModel {
  TaskNoteDetailsModel({
    required this.noteId,
    required this.createdDate,
    required this.createdBy,
    required this.note,
  });

  final String noteId;
  final String createdDate;
  final String createdBy;
  final String note;

  /// Creates a model from JSON.
  factory TaskNoteDetailsModel.fromJson(Map<String, dynamic> json) {
    return TaskNoteDetailsModel(
      noteId: json['id'] ?? '',
      createdDate: json['createdOnUtc'] ?? '',
      createdBy: (json['user']?['person']?['fullName'] as String?) ?? '',
      note: json['note'] ?? '',
    );
    }

  /// Parses a list of models from a JSON list.
  static List<TaskNoteDetailsModel> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((json) => TaskNoteDetailsModel.fromJson(json as Map<String, dynamic>)).toList();
  }
}
