import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:WorkBridge/application/workflow_orchestrator.dart';

class NotificationsList extends ConsumerWidget {
  final List<NotificationPayload> notifications;

  const NotificationsList({super.key, required this.notifications});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No notifications received yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Book a provider to simulate notification during the session.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[notifications.length - 1 - index];
        final isWhatsApp = notification.type == 'whatsapp';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isWhatsApp
                  ? Colors.green.shade100.withValues(alpha: 0.8)
                  : Colors.blue.shade100.withValues(alpha: 0.8),
              width: 1,
            ),
          ),
          color: isWhatsApp
              ? Colors.green.shade50.withValues(alpha: 0.3)
              : Colors.blue.shade50.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isWhatsApp
                        ? Colors.green.shade50
                        : Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isWhatsApp ? Icons.chat : Icons.sms,
                    color: isWhatsApp ? Colors.green : Colors.blueAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          height: 1.4,
                        ),
                      ),
                      if (notification.bookedBy != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isWhatsApp
                                ? Colors.green.shade100.withValues(alpha: 0.4)
                                : Colors.blue.shade100.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person_pin_rounded,
                                    size: 14,
                                    color: isWhatsApp
                                        ? Colors.green.shade800
                                        : Colors.blue.shade800,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Booked by:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isWhatsApp
                                          ? Colors.green.shade900
                                          : Colors.blue.shade900,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 19),
                                child: Text(
                                  notification.bookedBy!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isWhatsApp
                                        ? Colors.green.shade900
                                        : Colors.blue.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
