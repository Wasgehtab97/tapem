// lib/presentation/screens/affiliate/affiliate_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tapem/presentation/widgets/common/loading_indicator.dart';

// Bloc & State/Events
import 'package:tapem/presentation/blocs/affiliate/affiliate_bloc.dart';
import 'package:tapem/presentation/blocs/affiliate/affiliate_event.dart';
import 'package:tapem/presentation/blocs/affiliate/affiliate_state.dart';

// Nur die UseCases importieren (werden weiter oben in main.dart als Provider registriert)
import 'package:tapem/domain/usecases/affiliate/fetch_offers.dart'
    show FetchAffiliateOffersUseCase;
import 'package:tapem/domain/usecases/affiliate/track_click.dart'
    show TrackAffiliateClickUseCase;

/// Affiliate-Angebote anzeigen und Klicks tracken.
class AffiliateScreen extends StatelessWidget {
  const AffiliateScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AffiliateBloc>(
      create: (ctx) => AffiliateBloc(
        fetchOffers: ctx.read<FetchAffiliateOffersUseCase>(),
        trackClick: ctx.read<TrackAffiliateClickUseCase>(),
      )..add(AffiliateLoadOffers()),
      child: const _AffiliateView(),
    );
  }
}

class _AffiliateView extends StatelessWidget {
  const _AffiliateView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Affiliate Angebote')),
      body: BlocBuilder<AffiliateBloc, AffiliateState>(
        builder: (ctx, state) {
          if (state is AffiliateLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (state is AffiliateLoaded) {
            final offers = state.offers;
            if (offers.isEmpty) {
              return const Center(
                  child: Text('Keine Angebote verfügbar.'));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: offers.length,
              itemBuilder: (_, i) {
                final o = offers[i];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                          child: o.imageUrl.isNotEmpty
                              ? Image.network(
                                  o.imageUrl,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.image,
                                  size: 48,
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          o.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8),
                        child: Text(
                          o.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          // Klick tracken
                          context
                              .read<AffiliateBloc>()
                              .add(AffiliateTrackClick(o.id));
                          // Link öffnen
                          final uri = Uri.parse(o.affiliateUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Konnte Link nicht öffnen'),
                              ),
                            );
                          }
                        },
                        child: const Text('Ansehen'),
                      ),
                    ],
                  ),
                );
              },
            );
          }

          if (state is AffiliateError) {
            return Center(
                child: Text('Fehler: ${state.message}'));
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
