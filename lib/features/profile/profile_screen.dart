import 'package:flutter/material.dart';
import 'package:test_project/core/widgets/reusable_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusableAppBar(title: "Profile"),
      body: Column(
        children: [
          // Main content
          Expanded(
            child: Center(
              child: Text('Profile Screen', style: TextStyle(fontSize: 20)),
            ),
          ),

          // Bottom border line
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.grey.shade400,
          ),

          // Footer text
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: const [
                Text(
                  'Copyrights © 2025. All Rights Reserved',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  'Developed by VSky Solutions',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
