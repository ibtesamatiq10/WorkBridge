import 'package:flutter/material.dart';
import 'package:WorkBridge/data/maps/google_maps_initializer.dart';
import 'package:WorkBridge/domain/entities/booking.dart';
import 'package:WorkBridge/presentation/provider_map_screen.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final String reasoning;

  const BookingCard({
    super.key,
    required this.booking,
    required this.reasoning,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.deepPurple.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Provider Booking Results',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const Divider(height: 32),
            _buildSectionTitle('Service Type:'),
            _buildSectionBody(booking.request.serviceType),
            const SizedBox(height: 12),
            _buildSectionTitle('Location:'),
            _buildSectionBody(booking.request.location),
            const SizedBox(height: 12),
            _buildSectionTitle('Provider Address:'),
            _buildProviderAddress(context),
            const SizedBox(height: 12),

            _buildSectionTitle('Time:'),
            _buildSectionBody(booking.request.time),
            const SizedBox(height: 12),
            _buildSectionTitle('Recommended Provider:'),
            _buildSectionBody(
              '${booking.provider.name} (${booking.provider.distanceKm} km away)',
            ),
            const SizedBox(height: 12),
            _buildSectionTitle('Reasoning:'),
            _buildSectionBody(reasoning),
            const SizedBox(height: 12),
            _buildSectionTitle('Simulated Booking:'),
            _buildSectionBody('- Slot booked: ${booking.request.time}\n- Confirmation sent'),
            const SizedBox(height: 12),
            _buildSectionTitle('Follow-up:'),
            _buildSectionBody('Reminder scheduled 1 hour before appointment'),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSectionBody(String body) {
    return Text(
      body,
      style: const TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
    );
  }

  Widget _buildProviderAddress(BuildContext context) {
    final address = booking.provider.address;
    if (address == null || address.isEmpty) {
      return _buildSectionBody('No address available');
    }

    return InkWell(
      onTap: () async {
        await ensureGoogleMapsReady();
        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ProviderMapScreen(provider: booking.provider),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                address,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Colors.blueAccent,
                  decorationColor: Colors.black87,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black87),
          ],
        ),
      ),
    );
  }
}
