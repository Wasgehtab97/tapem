import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_services.dart';

class AffiliateScreen extends StatefulWidget {
  const AffiliateScreen({Key? key}) : super(key: key);

  @override
  State<AffiliateScreen> createState() => _AffiliateScreenState();
}

class _AffiliateScreenState extends State<AffiliateScreen> {
  final ApiService _api = ApiService();
  late Future<List<Map<String, dynamic>>> _offersFuture;

  @override
  void initState() {
    super.initState();
    _offersFuture = _api.getAffiliateOffers();
  }

  Future<void> _handleOfferTap(Map<String, dynamic> offer) async {
    await _api.trackAffiliateClick(offer['id'] as String);
    final url = offer['affiliate_url'] as String?;
    if (url != null && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Konnte den Link nicht öffnen')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Angebote"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _offersFuture,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Fehler: ${snap.error}'));
          }
          final offers = snap.data ?? [];
          if (offers.isEmpty) {
            return const Center(child: Text("Keine Angebote verfügbar."));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: .8,
            ),
            itemCount: offers.length,
            itemBuilder: (ctx, i) {
              final o = offers[i];
              return Card(
                child: Column(
                  children: [
                    Expanded(
                      child: o['image_url'] != null
                          ? Image.network(o['image_url'], fit: BoxFit.cover)
                          : const Icon(Icons.image, size: 48),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(o['title'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        o['description'] as String? ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _handleOfferTap(o),
                      child: const Text("Ansehen"),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
