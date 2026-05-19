import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:WorkBridge/application/workflow_orchestrator.dart';
import 'package:WorkBridge/data/maps/google_maps_initializer.dart';
import 'package:WorkBridge/domain/entities/provider.dart' as domain;

class ProviderMapScreen extends ConsumerStatefulWidget {
  final domain.Provider provider;

  const ProviderMapScreen({super.key, required this.provider});

  @override
  ConsumerState<ProviderMapScreen> createState() => _ProviderMapScreenState();
}

class _ProviderMapScreenState extends ConsumerState<ProviderMapScreen> {
  GoogleMapController? _mapController;
  LatLng? _position;
  String? _error;
  bool _sdkReady = false;
  bool _mapCreated = false;
  bool _geocoding = false;

  @override
  void initState() {
    super.initState();
    _initPosition();
    _prepareSdk();
  }

  void _initPosition() {
    final provider = widget.provider;
    if (provider.latitude != null && provider.longitude != null) {
      _position = LatLng(provider.latitude!, provider.longitude!);
      return;
    }

    final address = provider.address;
    if (address == null || address.isEmpty) {
      _error = 'No location available for this provider.';
      return;
    }

    _geocoding = true;
    _geocodeAddress(address);
  }

  Future<void> _prepareSdk() async {
    await ensureGoogleMapsReady();
    if (!mounted) return;
    setState(() => _sdkReady = true);
  }

  Future<void> _geocodeAddress(String address) async {
    final coords = await ref
        .read(providerRepositoryProvider)
        .geocodeAddress(address);
    if (!mounted) return;

    setState(() {
      _geocoding = false;
      if (coords == null) {
        _error = 'Could not find this address on the map.';
      } else {
        _position = LatLng(coords.$1, coords.$2);
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_mapCreated) return;
    setState(() => _mapCreated = true);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;

    return Scaffold(
      appBar: AppBar(title: Text(provider.name)),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(domain.Provider provider) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    if (_geocoding || !_sdkReady || _position == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Preparing map...'),
          ],
        ),
      );
    }

    final position = _position!;
    final markerId = MarkerId(provider.id);
    return Stack(
      children: [
        GoogleMap(
          key: ValueKey(provider.id),
          initialCameraPosition: CameraPosition(target: position, zoom: 15),
          markers: {
            Marker(
              markerId: markerId,
              position: position,
              infoWindow: InfoWindow(
                title: provider.name,
                snippet: provider.address,
              ),
            ),
          },
          buildingsEnabled: false,
          compassEnabled: false,
          indoorViewEnabled: false,
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
          trafficEnabled: false,
          zoomControlsEnabled: true,
          onMapCreated: _onMapCreated,
        ),
        if (!_mapCreated)
          const ColoredBox(
            color: Color(0xFFF5F5F5),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading map...'),
                ],
              ),
            ),
          ),
        if (provider.address != null && provider.address!.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, color: Colors.blueAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        provider.address!,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
