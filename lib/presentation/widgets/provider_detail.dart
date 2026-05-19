import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'package:WorkBridge/application/workflow_orchestrator.dart';
import 'package:WorkBridge/domain/entities/provider.dart';
import 'package:WorkBridge/domain/entities/service_request.dart';
import 'package:WorkBridge/data/maps/google_maps_initializer.dart';
import 'package:WorkBridge/presentation/provider_map_screen.dart';

class ProviderDetail extends ConsumerWidget {
  final ServiceRequest request;
  final Provider provider;
  final bool isRecommended;
  final String? recommendationReason;
  final bool isBooking;
  final VoidCallback onBack;
  final VoidCallback onBook;

  const ProviderDetail({
    super.key,
    required this.request,
    required this.provider,
    required this.onBack,
    required this.onBook,
    this.isRecommended = false,
    this.recommendationReason,
    this.isBooking = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workflowOrchestratorProvider);
    final isBusy = state.isProviderBusy(provider.id);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: isBooking ? null : onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to list'),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isBusy ? Colors.amber.shade50 : Colors.deepPurple.shade50,
                      child: Icon(
                        isBusy ? Icons.hourglass_top_rounded : Icons.store,
                        color: isBusy ? Colors.amber.shade800 : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.name,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            provider.serviceType,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isRecommended) ...[
                  const SizedBox(height: 12),
                  Chip(
                    avatar: const Icon(
                      Icons.star,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text('Agent recommended'),
                    backgroundColor: Colors.deepPurple,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                ],
                if (isBusy) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.hourglass_empty_rounded, color: Colors.amber.shade800),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This provider is executing another booking and will become available in ${state.busySecondsRemaining(provider.id)} seconds.',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _InfoTile(
                  icon: Icons.star_rate,
                  label: 'Rating',
                  valueIcon: Icons.star_rate,
                  valueColor: const Color(0xFFffa534),
                  value:
                      '${provider.rating.toStringAsFixed(1)}${provider.totalRatings != null ? ' (${provider.totalRatings} reviews)' : ''}',
                ),
                _InfoTile(
                  icon: Icons.near_me,
                  label: 'Distance',
                  value: '${provider.distanceKm} km from search area',
                ),
                _InfoTile(
                  icon: Icons.schedule,
                  label: 'Requested time',
                  value: request.time,
                ),
                _InfoTile(
                  icon: Icons.location_on_outlined,
                  label: 'Search location',
                  value: request.location,
                ),
                if (provider.address != null && provider.address!.isNotEmpty)
                  _InfoTile(
                    icon: Icons.map,
                    label: 'Address',
                    value: provider.address!,
                    onTap: () async {
                      await ensureGoogleMapsReady();
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ProviderMapScreen(provider: provider),
                        ),
                      );
                    },
                  ),
                _InfoTile(
                  icon: Icons.info_outline,
                  label: 'Status',
                  value: isBusy
                      ? 'Busy / Occupied'
                      : provider.isAvailable
                          ? 'Open / operational'
                          : 'Unavailable',
                ),
                if (recommendationReason != null &&
                    recommendationReason!.isNotEmpty &&
                    isRecommended) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.deepPurple.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Why we recommend this',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(recommendationReason!),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (isBooking || isBusy) ? null : onBook,
                style: isBusy
                    ? FilledButton.styleFrom(
                        backgroundColor: Colors.amber.shade100,
                        foregroundColor: Colors.amber.shade900,
                      )
                    : null,
                icon: isBooking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(isBusy ? Icons.hourglass_top_rounded : Icons.event_available),
                label: Text(
                  isBooking
                      ? 'Booking...'
                      : isBusy
                          ? 'Provider Busy (${state.busySecondsRemaining(provider.id)}s)'
                          : 'Book this provider',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final IconData? valueIcon;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.valueIcon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: Colors.black),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (valueIcon != null) ...[
                    Icon(
                      valueIcon,
                      size: 20,
                      color: valueColor ?? Colors.black,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: onTap != null ? Colors.blueAccent : null,
                        decorationColor: onTap != null ? Colors.black87 : null,
                        decoration: onTap != null
                            ? TextDecoration.underline
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (onTap != null) Icon(Icons.chevron_right, color: Colors.black87),
      ],
    );

    if (onTap == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: content,
          ),
        ),
      ),
    );
  }
}
