import 'package:WorkBridge/domain/entities/provider.dart';
import 'package:WorkBridge/domain/entities/service_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'package:WorkBridge/application/workflow_orchestrator.dart';

class ProvidersList extends ConsumerWidget {
  final ServiceRequest request;
  final List<Provider> providers;
  final Provider? recommendedProvider;
  final ValueChanged<Provider> onProviderTap;

  const ProvidersList({
    super.key,
    required this.request,
    required this.providers,
    required this.onProviderTap,
    this.recommendedProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workflowOrchestratorProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${request.serviceType} near ${request.location}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        if (request.time.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'When: ${request.time}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          '${providers.length} places found · tap for details',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        ...providers.map((provider) {
          final isRecommended = recommendedProvider?.id == provider.id;
          final isBusy = state.isProviderBusy(provider.id);

          return Opacity(
            opacity: isBusy ? 0.75 : 1.0,
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: isRecommended && !isBusy ? 3 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isRecommended && !isBusy
                      ? Colors.black
                      : isBusy
                          ? Colors.amber.shade300
                          : Colors.grey.shade200,
                  width: isRecommended && !isBusy ? 2 : 1,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onProviderTap(provider),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: isRecommended && !isBusy
                        ? Colors.black
                        : isBusy
                            ? Colors.amber.shade50
                            : Colors.deepPurple.shade50,
                    child: Icon(
                      isBusy ? Icons.hourglass_top_rounded : Icons.place,
                      color: isRecommended && !isBusy
                          ? Colors.white
                          : isBusy
                              ? Colors.amber.shade800
                              : Colors.black,
                    ),
                  ),
                  title: Text(
                    provider.name,
                    style: TextStyle(
                      fontWeight: isRecommended && !isBusy
                          ? FontWeight.bold
                          : FontWeight.w600,
                    ),
                  ),
                  subtitle: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.star_rate,
                        size: 20,
                        color: Color(0xFFffa534),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          ' ${provider.rating.toStringAsFixed(1)}  · ${provider.distanceKm} km'
                          '${provider.address != null ? '\n${provider.address}' : ''}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isBusy)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade300),
                            ),
                            child: Text(
                              'Busy • ${state.busySecondsRemaining(provider.id)}s',
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      else if (isRecommended)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Chip(
                            label: Text(
                              'Top pick',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                            backgroundColor: Colors.blueAccent,
                            labelStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      const Icon(Icons.chevron_right, color: Colors.black87),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
