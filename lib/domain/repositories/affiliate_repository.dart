// lib/domain/repositories/affiliate_repository.dart

import '../models/affiliate_offer.dart';

/// Schnittstelle für Affiliate-Feature.
abstract class AffiliateRepository {
  /// Holt alle verfügbaren Affiliate-Angebote.
  Future<List<AffiliateOffer>> fetchOffers();

  /// Trackt einen Klick auf das Angebot [offerId].
  Future<void> trackClick(String offerId);
}
