import 'package:flutter/material.dart';

class MyDailyPlan extends StatelessWidget {
  const MyDailyPlan({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Plan Screen',
      home: DailyPlanScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DailyPlanScreen extends StatelessWidget {
  const DailyPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Daily Plan Screen',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
