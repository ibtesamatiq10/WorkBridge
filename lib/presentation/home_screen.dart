import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:WorkBridge/application/workflow_orchestrator.dart';
import 'package:WorkBridge/presentation/widgets/booking_card.dart';
import 'package:WorkBridge/presentation/widgets/chat_input.dart';
import 'package:WorkBridge/presentation/widgets/provider_detail.dart';
import 'package:WorkBridge/presentation/widgets/providers_list.dart';
import 'package:WorkBridge/presentation/widgets/notifications_list.dart';
import 'package:WorkBridge/presentation/widgets/notification_banner.dart';
import 'package:WorkBridge/data/notifications/notification_service.dart';
import 'package:WorkBridge/application/auth_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocalNotificationService.initialize();
    });

    final state = ref.watch(workflowOrchestratorProvider);
    final notifier = ref.read(workflowOrchestratorProvider.notifier);
    final isMobile = MediaQuery.of(context).size.width < 800;

    ref.listen(authControllerProvider, (previous, next) {
      if (next.user != null) {
        ref
            .read(workflowOrchestratorProvider.notifier)
            .loadHistoryForUser(next.user!.uid);
      }
    });

    final currentUserId = ref.read(authControllerProvider).user?.uid;
    if (currentUserId != null && state.notifications.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(workflowOrchestratorProvider.notifier)
            .loadHistoryForUser(currentUserId);
      });
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('WorkBridge Orchestrator'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Logout',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    builder: (sheetContext) {
                      return SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.logout_rounded,
                                    color: Color(0xFFDC2626),
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Are you sure you want to logout?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E1B4B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'You will need to enter your email and password again to sign back in.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(sheetContext),
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        side: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: Color(0xFF4B5563),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        Navigator.pop(sheetContext);
                                        await ref
                                            .read(authControllerProvider.notifier)
                                            .logout();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                'Logged out successfully.',
                                              ),
                                              backgroundColor: Colors.blue.shade900,
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFEF4444),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'Logout',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          body: isMobile
              ? _buildMobileLayout(context, ref, state, notifier)
              : _buildDesktopLayout(context, ref, state, notifier),
        ),
        const CustomNotificationBanner(),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    WorkflowState state,
    WorkflowOrchestrator notifier,
  ) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Results'),
              Tab(text: 'Notifications'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                Column(
                  children: [
                    Expanded(child: _buildResultView(state, notifier)),
                    ChatInput(
                      isProcessing: state.isProcessing,
                      onSubmit: notifier.processUserRequest,
                    ),
                  ],
                ),
                NotificationsList(notifications: state.notifications),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    WorkflowState state,
    WorkflowOrchestrator notifier,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Expanded(child: _buildResultView(state, notifier)),
              ChatInput(
                isProcessing: state.isProcessing,
                onSubmit: notifier.processUserRequest,
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade200,
                child: const Text(
                  'Notifications History',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Expanded(
                child: NotificationsList(notifications: state.notifications),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultView(WorkflowState state, WorkflowOrchestrator notifier) {
    if (state.booking != null && state.reasoning != null) {
      return Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: notifier.dismissBooking,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to provider list'),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: BookingCard(
                booking: state.booking!,
                reasoning: state.reasoning!,
              ),
            ),
          ),
        ],
      );
    }

    if (state.viewedProvider != null && state.currentRequest != null) {
      final provider = state.viewedProvider!;
      return ProviderDetail(
        request: state.currentRequest!,
        provider: provider,
        isRecommended: state.recommendedProvider?.id == provider.id,
        recommendationReason: state.reasoning,
        isBooking: state.isProcessing,
        onBack: notifier.backToProviderList,
        onBook: () => notifier.bookProvider(provider),
      );
    }

    if (state.matchedProviders.isNotEmpty && state.currentRequest != null) {
      return ProvidersList(
        request: state.currentRequest!,
        providers: state.matchedProviders,
        recommendedProvider: state.recommendedProvider,
        onProviderTap: notifier.showProviderDetail,
      );
    }

    if (state.isProcessing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.blueAccent),
            SizedBox(height: 16),
            Text('Searching for providers...'),
          ],
        ),
      );
    }

    if (state.logs.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            state.matchedProviders.isEmpty
                ? 'No providers found for your request.\nCheck the Agent Logs tab for Maps API details.'
                : 'Something went wrong.\nCheck the Agent Logs tab for details.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.redAccent),
          ),
        ),
      );
    }

    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Text(
          'Describe the service you need.\nExample: "Restaurant in Gulberg, Lahore, Pakistan" or "Plumber in Dubai Marina, UAE"',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
