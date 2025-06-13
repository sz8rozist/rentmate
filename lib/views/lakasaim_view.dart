import 'package:flutter/material.dart';
import 'package:rentmate/models/flat_status.dart';

import '../models/flat_model.dart';

class LakasaimView extends StatelessWidget {
  const LakasaimView({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight;
    final List<Flat> flats = [
      Flat(
        address: 'Budapest, Károly körút 12.',
        imageUrl:
            'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
        price: 180,
        status: FlatStatus.active,
      ),
      Flat(
        address: 'Szeged, Petőfi Sándor utca 8.',
        imageUrl:
            'https://images.unsplash.com/photo-1599423300746-b62533397364?auto=format&fit=crop&w=800&q=80',
        price: 180,
        status: FlatStatus.inactive,
        tenant: 'Rózsa István',
      ),
      Flat(
        address: 'Pécs, Király utca 22.',
        imageUrl:
            'https://images.unsplash.com/photo-1599423300746-b62533397364?auto=format&fit=crop&w=800&q=80',
        price: 180,
        status: FlatStatus.inactive,
        tenant: 'Kele Dominik',
      ),
    ];

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 10),
      itemCount: flats.length,
      itemBuilder: (context, index) {
        final flat = flats[index];
        return FlatCard(flat: flat);
      },
    );
  }
}

class FlatCard extends StatelessWidget {
  final Flat flat;

  const FlatCard({super.key, required this.flat});

  Color _getStatusColor(FlatStatus status) {
    switch (status.value) {
      case 'szabad':
        return Colors.green.shade100;
      case 'kiadva':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade300;
    }
  }

  Color _getStatusTextColor(FlatStatus status) {
    switch (status.value) {
      case 'szabad':
        return Colors.green.shade800;
      case 'kiadva':
        return Colors.red.shade800;
      default:
        return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              flat.imageUrl ?? '',
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  flat.address,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(flat.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    flat.status.label,
                    style: TextStyle(
                      color: _getStatusTextColor(flat.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (flat.tenant != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Bérlő: ${flat.tenant}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Részletek'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
