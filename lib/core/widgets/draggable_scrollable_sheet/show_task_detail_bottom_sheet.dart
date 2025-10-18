import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/widgets/custom_snackbar.dart';
import 'package:test_project/features/my_task_and_activity/my_task_and_activity_service.dart';

Future<void> showTaskDetailBottomSheet(
  BuildContext context, {
  required String id,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TaskDetailSheet(id: id),
  );
}

class _TaskDetailSheet extends StatefulWidget {
  const _TaskDetailSheet({required this.id});
  final String id;

  @override
  State<_TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<_TaskDetailSheet> {
  late Future<String> _futureHtml;

  @override
  void initState() {
    super.initState();
    _futureHtml = _loadDescription(widget.id);
  }

  Future<String> _loadDescription(String id) async {
    const fallback = 'No Description available';
    if (id.trim().isEmpty) return fallback;
    try {
      final response =
          await MyTaskAndActivityService.instance.fetchTaskDescriptionById(id);
      if (response.statusCode == 200) {
        final map = response.data;
        final desc = map['description'];
        return (desc == null || desc.isEmpty) ? fallback : desc;
      } else
        return fallback;
    } catch (_) {
      return fallback;
    }
  }

  // Minimal HTML -> plain text converter for copy action.
  String _cleanText(String input) =>
      input.replaceAll('\u00A0', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  String _htmlToPlainText(String? html) {
    if (html == null || html.trim().isEmpty) return 'No Description available';
    try {
      if (!html.contains('<') || !html.contains('>')) {
        return _cleanText(html);
      }
      final doc = html_parser.parse(html);
      return _cleanText(doc.body?.text ?? html);
    } catch (_) {
      return _cleanText(html.replaceAll(RegExp(r'<[^>]*>'), ' '));
    }
  }

  Future<void> _copy(BuildContext context, String html) async {
    final plain = _htmlToPlainText(html);
    await Clipboard.setData(ClipboardData(text: plain));
    if (!mounted) return;
    Fluttertoast.showToast(msg: "Copied");
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.25,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: const [
              BoxShadow(
                  blurRadius: 12, color: Colors.black26, offset: Offset(0, -2)),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        height: 5,
                        width: 48,
                        decoration: BoxDecoration(
                          color: onSurface.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Task Description',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: FutureBuilder<String>(
                        future: _futureHtml,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
                          final htmlContent = snapshot.data?.trim() ?? '';
                          final hasHtml = htmlContent.isNotEmpty &&
                              htmlContent != 'No Description available';
                          return SingleChildScrollView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                            child: hasHtml
                                ? Html(
                                    data: htmlContent,
                                    style: {
                                      "ul": Style(margin: Margins.zero),
                                      "li": Style(
                                        margin: Margins.only(bottom: 8),
                                        listStylePosition:
                                            ListStylePosition.outside,
                                      ),
                                      "p": Style(margin: Margins.zero),
                                    },
                                  )
                                : const Text('No Description available'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FutureBuilder<String>(
                    future: _futureHtml,
                    builder: (context, snapshot) {
                      final canCopy = snapshot.hasData &&
                          snapshot.data != null &&
                          snapshot.data!.trim().isNotEmpty &&
                          snapshot.data!.trim() != 'No Description available';
                      return FloatingActionButton(
                        heroTag: 'copyTaskDescriptionFab',
                        backgroundColor: AppColors.PRIMARY, // as requested
                        onPressed:
                            canCopy ? () => _copy(context, snapshot.data!.trim()) : null,
                        child: const Icon(Icons.copy, color: Colors.white),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
