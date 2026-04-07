import 'package:flutter/material.dart';
import '../screens/announcements_screen.dart';
import '../services/queue_service.dart';

class AnnouncementIcon extends StatelessWidget {
  final Color color;
  const AnnouncementIcon({super.key, this.color = const Color(0xFF05264E)});

  @override
  Widget build(BuildContext context) {
    final QueueService queueService = QueueService();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AnnouncementsScreen()),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_none_outlined,
              color: color,
              size: 28,
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: queueService.streamAnnouncements(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                // For simplicity, we just show a red dot if any announcements exist.
                // In a real app, you'd track 'last seen' in local storage.
                return Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
