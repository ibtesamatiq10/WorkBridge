class WorkflowLog {
  final DateTime timestamp;
  final String step;
  final String message;

  const WorkflowLog({
    required this.timestamp,
    required this.step,
    required this.message,
  });
}
