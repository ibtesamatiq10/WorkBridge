class ServiceRequest {
  final String serviceType;
  final String location;
  final String time;

  const ServiceRequest({
    required this.serviceType,
    required this.location,
    required this.time,
  });

  @override
  String toString() => 'Service: $serviceType, Location: $location, Time: $time';
}
