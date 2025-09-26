import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';

import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/widgets/info_row/info_row_widget.dart';
import 'package:test_project/features/my_task_and_activity/model/project_activity_details_model.dart';
import 'package:test_project/features/my_task_and_activity/my_task_and_activity_service.dart';

/// Screen that shows read-only details of a project activity.[1]
class ProjectActivityDetailsScreen extends StatefulWidget {
  const ProjectActivityDetailsScreen({super.key, required this.id});

  /// Project activity identifier to view.[1]
  final String id;

  @override
  State<ProjectActivityDetailsScreen> createState() => _ProjectActivityDetailsScreenState();
}

class _ProjectActivityDetailsScreenState extends State<ProjectActivityDetailsScreen> {
  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Variable Declarations
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  ProjectActivityDetailsModel? _activityDetails;
  bool _isLoading = true;

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Lifecycle
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Initializes the screen and triggers the details fetch.[1]
  @override
  void initState() {
    super.initState();
    _fetchActivityDetails();
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// API Calls & Data Ops
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Fetches activity details by id and updates loading state.[1]
  Future<void> _fetchActivityDetails() async {
    try {
      final response = await MyTaskAndActivityService.instance.getProjectActivityDetails(widget.id);
      if (response.statusCode == 200) {
        setState(() {
          _activityDetails = ProjectActivityDetailsModel.fromJson(response.data);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Fetch activity details error: $e');
      setState(() => _isLoading = false);
    }
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Actions & Event Handlers
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Handles back navigation from app bar and FAB.[1]
  void _onBackPressed() {
    context.pop();
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// UI
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Builds the complete details page UI.[1]
  @override
  Widget build(BuildContext context) {
    final String titleText = _activityDetails != null ? (_activityDetails?.name ?? '-') : 'Activity Details';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _onBackPressed,
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          titleText,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.PRIMARY,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildActivityInfoSection(_activityDetails),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onBackPressed,
        heroTag: 'back',
        backgroundColor: AppColors.PRIMARY,
        child: const Icon(Icons.arrow_back, color: Colors.white),
        tooltip: 'Back',
      ),
    );
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// UI Helpers
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Builds the main info section using InfoRow and an HTML description block.[1]
  Widget _buildActivityInfoSection(ProjectActivityDetailsModel? details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activity Info',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.PRIMARY,
          ),
        ),
        SizedBox(height: 18,),
        InfoRow(
          label: 'Project Name',
          value: details?.projectName ?? '-',
        ),
        InfoRow(
          label: 'Project Module Name',
          value: details?.projectModuleName ?? '-',
        ),
        InfoRow(
          label: 'Project Task Name',
          value: details?.taskName ?? '-',
        ),
        InfoRow(
          label: 'Activity Name',
          value: details?.name ?? '-',
          valueDetails: details?.activityNameDescription
        ),
        InfoRow(
          label: 'Estimate Hrs',
          value: details?.estimateHours?.toString() ?? '-',
        ),
        InfoRow(
          label: 'Activity Owner',
          value: '${details?.assignedTo.person.firstName ?? ''} ${details?.assignedTo.person.lastName ?? ''}',
        ),
        InfoRow(
          label: 'Activity Status',
          value: details?.activityStatus.dropDownValue ?? '-',
        ),
        const SizedBox(height: 8),
        _buildHtmlDescription(details?.description ?? '-'),
        const SizedBox(height: 8),
        InfoRow(
          label: 'Created By',
          value: details?.createdByUser.person.fullName ?? '-',
        ),
        InfoRow(
          label: 'Updated By',
          value: details?.updatedByUser.person.fullName ?? '-',
        ),
        InfoRow(
          label: 'Created Date',
          value: details?.createdOnUtc ?? '-',
        ),
        InfoRow(
          label: 'Updated Date',
          value: details?.updatedOnUtc ?? '-',
        ),
      ],
    );
  }

  /// Builds the HTML-rendered activity description with tightened spacing.[1]
  Widget _buildHtmlDescription(String html) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          flex: 2,
          child: Text(
            'Activity Details:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.PRIMARY,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Html(
            data: html,
            style: {
              'ul': Style(margin: Margins.zero),
              'li': Style(
                margin: Margins.zero,
                listStylePosition: ListStylePosition.outside,
              ),
              'p': Style(margin: Margins.zero),
              'body': Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
              ),
            },
          ),
        ),
      ],
    );
  }
}
  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Model
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

