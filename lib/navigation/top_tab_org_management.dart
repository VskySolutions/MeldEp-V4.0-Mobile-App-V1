import 'package:flutter/material.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/features/org_management/apply_leave/apply_leave_screen.dart';
import 'package:test_project/core/widgets/reusable_app_bar.dart';

class TopTabOrgManagement extends StatelessWidget {
  const TopTabOrgManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: ReusableAppBar(title: "Org Management"),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              child: TabBar(
                labelColor: AppColors.PRIMARY,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.PRIMARY,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal, fontSize: 14),
                tabs: const [
                  Tab(text: 'Apply Leave'),
                  Tab(text: 'Approve Leaves'),
                  Tab(text: 'Training Portal'),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  ApplyLeaveScreen(),
                  const Center(child: Text('Approve Leaves...')),
                  const Center(child: Text('Training Portal...')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
