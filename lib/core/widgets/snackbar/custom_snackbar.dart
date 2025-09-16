import 'package:flutter/material.dart';

void showCustomSnackBar(
  BuildContext context, {
  required String message,
  Color backgroundColor = Colors.green,
  int durationSeconds = 4,
}) {
  final snackBar = SnackBar(
    content: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(message)),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          child: const Icon(Icons.close, color: Colors.white),
        ),
      ],
    ),
    backgroundColor: backgroundColor,
    behavior: SnackBarBehavior.fixed,
    duration: Duration(seconds: durationSeconds),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
