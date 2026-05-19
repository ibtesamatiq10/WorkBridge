import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:WorkBridge/application/workflow_orchestrator.dart';

class CustomNotificationBanner extends ConsumerStatefulWidget {
  const CustomNotificationBanner({super.key});

  @override
  ConsumerState<CustomNotificationBanner> createState() =>
      _CustomNotificationBannerState();
}

class _CustomNotificationBannerState
    extends ConsumerState<CustomNotificationBanner> {
  NotificationPayload? _previousPayload;

  @override
  Widget build(BuildContext context) {
    final activeNotification = ref.watch(
      workflowOrchestratorProvider.select((s) => s.activeNotification),
    );

    if (activeNotification != null && activeNotification != _previousPayload) {
      _previousPayload = activeNotification;
      Future.microtask(() {
        HapticFeedback.vibrate();
      });
    } else if (activeNotification == null) {
      _previousPayload = null;
    }

    final isVisible = activeNotification != null;
    final topPadding = MediaQuery.of(context).padding.top;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
      top: isVisible ? topPadding + 12 : -180,
      left: 16,
      right: 16,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: isVisible
              ? Dismissible(
                  key: UniqueKey(),
                  direction: DismissDirection.up,
                  onDismissed: (_) {
                    ref
                        .read(workflowOrchestratorProvider.notifier)
                        .dismissNotification();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Material(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: activeNotification.type == 'whatsapp'
                                    ? const Color(0xFF25D366)
                                    : const Color(0xFF007AFF),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (activeNotification.type == 'whatsapp'
                                                ? const Color(0xFF25D366)
                                                : const Color(0xFF007AFF))
                                            .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                activeNotification.type == 'whatsapp'
                                    ? Icons.chat_bubble_rounded
                                    : Icons.textsms_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        activeNotification.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: Colors.grey.shade800,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const Text(
                                        'now',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black38,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    activeNotification.body,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                      height: 1.35,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
