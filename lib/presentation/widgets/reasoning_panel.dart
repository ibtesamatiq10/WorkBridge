import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:WorkBridge/domain/entities/workflow_log.dart';

class ReasoningPanel extends StatelessWidget {
  final List<WorkflowLog> logs;

  const ReasoningPanel({Key? key, required this.logs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: logs.isEmpty
          ? const Center(
              child: Text(
                'Waiting for task...',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getColorForStep(log.step).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getColorForStep(log.step).withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          log.step,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getColorForStep(log.step),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.message,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('HH:mm:ss').format(log.timestamp),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Color _getColorForStep(String step) {
    if (step.contains('Agent Action') || step.contains('Agent Decision')) {
      return Colors.purple;
    } else if (step.contains('System Action') || step.contains('Discovery')) {
      return Colors.blue;
    } else if (step.contains('Confirmed') || step.contains('Scheduled')) {
      return Colors.green;
    } else if (step.contains('Error')) {
      return Colors.red;
    }
    return Colors.black87;
  }
}
