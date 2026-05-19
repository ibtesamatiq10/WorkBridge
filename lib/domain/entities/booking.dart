import 'package:WorkBridge/domain/entities/provider.dart';
import 'package:WorkBridge/domain/entities/service_request.dart';

class Booking {
  final String id;
  final ServiceRequest request;
  final Provider provider;
  final String status;
  final DateTime scheduledTime;

  const Booking({
    required this.id,
    required this.request,
    required this.provider,
    required this.status,
    required this.scheduledTime,
  });
}
