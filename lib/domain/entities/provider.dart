class Provider {
  final String id;
  final String name;
  final String serviceType;
  final double rating;
  final double distanceKm;
  final bool isAvailable;
  final String? address;
  final int? totalRatings;
  final double? latitude;
  final double? longitude;

  const Provider({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.rating,
    required this.distanceKm,
    required this.isAvailable,
    this.address,
    this.totalRatings,
    this.latitude,
    this.longitude,
  });
}
