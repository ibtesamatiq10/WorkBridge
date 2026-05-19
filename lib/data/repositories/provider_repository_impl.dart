import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:WorkBridge/domain/entities/provider.dart';

class ProviderSearchResult {
  final List<Provider> providers;
  final String? diagnosticMessage;

  const ProviderSearchResult({required this.providers, this.diagnosticMessage});
}

class ProviderRepository {
  final String apiKey;

  ProviderRepository(this.apiKey);

  Future<ProviderSearchResult> findNearbyProviders(
    String serviceType,
    String location,
  ) async {
    if (apiKey == 'YOUR_MAPS_API_KEY_HERE' || apiKey.isEmpty) {
      return const ProviderSearchResult(
        providers: [],
        diagnosticMessage:
            'Google Maps API key is missing. Add GOOGLE_MAPS_API_KEY to .env',
      );
    }

    final normalizedLocation = _normalizeLocation(location);
    final queries = _buildSearchQueries(serviceType, normalizedLocation);

    double? lat;
    double? lng;

    if (normalizedLocation != 'Unknown' && normalizedLocation.isNotEmpty) {
      final coords = await _geocode(normalizedLocation);
      lat = coords?.$1;
      lng = coords?.$2;
    }

    for (final query in queries) {
      final result = await _searchPlaces(
        query: query,
        serviceType: serviceType,
        lat: lat,
        lng: lng,
      );
      if (result.providers.isNotEmpty) {
        return result;
      }
      if (result.diagnosticMessage != null && kDebugMode) {
        debugPrint('Places search ($query): ${result.diagnosticMessage}');
      }
    }

    if (normalizedLocation == 'Unknown') {
      return const ProviderSearchResult(
        providers: [],
        diagnosticMessage:
            'No city or area detected. Include a city and country in your message (e.g. "restaurant in Gulberg, Lahore, Pakistan").',
      );
    }

    return const ProviderSearchResult(
      providers: [],
      diagnosticMessage: 'No places found for this service and location.',
    );
  }

  String _normalizeLocation(String location) {
    final trimmed = location.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'unknown') {
      return 'Unknown';
    }
    return trimmed;
  }

  List<String> _buildSearchQueries(String serviceType, String location) {
    final type = serviceType.trim();
    if (location == 'Unknown') {
      return [];
    }
    final placeQuery = location;
    final lowerType = type.toLowerCase();

    if (lowerType.contains('restaurant') || lowerType.contains('food')) {
      return [
        'restaurants in $placeQuery',
        'restaurant in $placeQuery',
        type.isEmpty ? 'restaurants in $placeQuery' : '$type in $placeQuery',
      ];
    }

    return [
      '$type in $placeQuery',
      if (location != 'Unknown') '$type near $location',
    ];
  }

  Future<(double, double)?> geocodeAddress(String address) => _geocode(address);

  Future<(double, double)?> _geocode(String location) async {
    final geocodeUrl = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      {'address': location, 'key': apiKey},
    );

    try {
      final response = await http.get(geocodeUrl);
      if (response.statusCode != 200) {
        return null;
      }
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
        final locationData =
            (data['results'] as List).first['geometry']['location']
                as Map<String, dynamic>;
        return (
          (locationData['lat'] as num).toDouble(),
          (locationData['lng'] as num).toDouble(),
        );
      }
    } catch (e) {
      debugPrint('Error geocoding location: $e');
    }
    return null;
  }

  Future<ProviderSearchResult> _searchPlaces({
    required String query,
    required String serviceType,
    double? lat,
    double? lng,
  }) async {
    final params = <String, String>{'query': query, 'key': apiKey};
    if (lat != null && lng != null) {
      params['location'] = '$lat,$lng';
      params['radius'] = '10000';
    }

    final searchUrl = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/textsearch/json',
      params,
    );

    try {
      final response = await http.get(searchUrl);
      if (response.statusCode != 200) {
        return ProviderSearchResult(
          providers: [],
          diagnosticMessage: 'Places API HTTP ${response.statusCode}',
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'UNKNOWN';

      if (status != 'OK') {
        final errorMessage = data['error_message'] as String?;
        return ProviderSearchResult(
          providers: [],
          diagnosticMessage: errorMessage ?? 'Places API status: $status',
        );
      }

      final results = data['results'] as List;
      final providers = results
          .take(8)
          .map((place) {
            final placeLat = (place['geometry']['location']['lat'] as num)
                .toDouble();
            final placeLng = (place['geometry']['location']['lng'] as num)
                .toDouble();

            double distance = 0.0;
            if (lat != null && lng != null) {
              distance = _calculateDistance(lat, lng, placeLat, placeLng);
            } else {
              distance = (Random().nextDouble() * 10) + 1;
            }

            final businessStatus = place['business_status'] as String?;
            final isOpen =
                businessStatus == null ||
                businessStatus == 'OPERATIONAL' ||
                businessStatus == 'OPEN';

            return Provider(
              id:
                  place['place_id'] as String? ??
                  Random().nextInt(10000).toString(),
              name: place['name'] as String? ?? 'Unknown Provider',
              serviceType: serviceType,
              rating: ((place['rating'] as num?) ?? 4.0).toDouble(),
              distanceKm: double.parse(distance.toStringAsFixed(1)),
              isAvailable: isOpen,
              address:
                  place['formatted_address'] as String? ??
                  place['vicinity'] as String?,
              totalRatings: (place['user_ratings_total'] as num?)?.toInt(),
              latitude: placeLat,
              longitude: placeLng,
            );
          })
          .where((p) => p.isAvailable)
          .toList();

      return ProviderSearchResult(providers: providers);
    } catch (e) {
      debugPrint('Error searching places: $e');
      return ProviderSearchResult(
        providers: [],
        diagnosticMessage: e.toString(),
      );
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295;
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}
