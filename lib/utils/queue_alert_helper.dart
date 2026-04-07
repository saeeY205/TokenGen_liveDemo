import 'package:flutter/material.dart';
import '../screens/queue_alert_screen.dart';

class QueueAlertHelper {
  static int calculatePeopleAhead(int userToken, int currentServingToken) {
    return userToken - currentServingToken;
  }

  static void showQueueAlert(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const QueueAlertScreen(),
    );
  }
}
