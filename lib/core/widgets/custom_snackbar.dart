import 'package:flutter/material.dart';

void showCustomSnackBar(
  BuildContext context, {
  required String message,
  Color backgroundColor = Colors.green,
  int durationSeconds = 4,
  Color contentColor = Colors.white,
}) {
  final snackBar = SnackBar(
    content: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(message, style: TextStyle(color: contentColor)), ),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          child: Icon(Icons.close, color: contentColor),
        ),
      ],
    ),
    backgroundColor: backgroundColor,
    behavior: SnackBarBehavior.fixed,
    duration: Duration(seconds: durationSeconds),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
