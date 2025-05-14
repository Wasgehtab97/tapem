import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tapem/presentation/blocs/affiliate/affiliate_bloc.dart';
import 'package:tapem/presentation/blocs/affiliate/affiliate_event.dart';
import 'package:tapem/presentation/blocs/affiliate/affiliate_state.dart';
import 'package:tapem/domain/models/affiliate_offer.dart';

/// Zeigt eine Übersicht aller Affiliate-Angebote in einem Grid.
/// Handhabt Klicks über den AffiliateBloc und öffnet Links extern.
class AffiliateOfferList extends StatelessWidget {
  const AffiliateOfferList({Key? key}) : super(key: key);

  Future<void> _openOffer(BuildContext context, String id, String url) async {
    // Klick tracken
    context.read<AffiliateBloc>().add(AffiliateTrackClick(id));

    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link konnte nicht geöffnet werden')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AffiliateBloc, AffiliateState>(
      builder: (context, state) {
        if (state is AffiliateLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AffiliateError) {
          return Center(child: Text('Fehler: ${state.message}'));
        }

        if (state is AffiliateLoaded) {
          final offers = state.offers;
          if (offers.isEmpty) {
            return const Center(child: Text('Keine Angebote verfügbar.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: offers.length,
            itemBuilder: (context, i) {
              final AffiliateOffer offer = offers[i];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                clipBehavior: Clip.hardEdge,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Bild oder Platzhalter
                    Expanded(
                      child: offer.imageUrl.isNotEmpty
                          ? Image.network(
                              offer.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, _, __) => const Icon(Icons.broken_image),
                            )
                          : const Icon(Icons.image, size: 48),
                    ),

                    // Titel
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        offer.title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Beschreibung
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        offer.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const Spacer(),

                    // „Ansehen“-Button
                    TextButton(
                      onPressed: () => _openOffer(
                        context,
                        offer.id,
                        offer.affiliateUrl,
                      ),
                      child: const Text('Ansehen'),
                    ),
                  ],
                ),
              );
            },
          );
        }

        // Fallback
        return const SizedBox.shrink();
      },
    );
  }
}
