import 'package:flutter/material.dart';
import '../utils/queue_alert_helper.dart';

class QueueNotificationService {
  bool _alertShown = false;

  void checkAndNotify(BuildContext context, int userToken, int currentServingToken) {
    if (_alertShown) return;

    int peopleAhead = QueueAlertHelper.calculatePeopleAhead(userToken, currentServingToken);

    if (peopleAhead == 3) {
      _alertShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        QueueAlertHelper.showQueueAlert(context);
      });
    }
  }

  void resetAlert() {
    _alertShown = false;
  }
}
