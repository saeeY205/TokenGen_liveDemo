import 'package:flutter/material.dart';

class QueueAlertScreen extends StatelessWidget {
  const QueueAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "⚠️ Your turn is coming soon",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: const Text(
        "Only 3 people are ahead of you. Please be ready!",
        style: TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            "OK",
            style: TextStyle(
              color: Color(0xFF2DD4BF),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
