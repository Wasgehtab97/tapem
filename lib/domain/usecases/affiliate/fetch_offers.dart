// lib/domain/usecases/affiliate/fetch_offers.dart

import 'package:tapem/domain/models/affiliate_offer.dart';
import 'package:tapem/domain/repositories/affiliate_repository.dart';

/// UseCase zum Laden aller Affiliate-Angebote.
class FetchAffiliateOffersUseCase {
  final AffiliateRepository _repository;

  FetchAffiliateOffersUseCase(this._repository);

  /// Holt und liefert die Liste der [AffiliateOffer].
  Future<List<AffiliateOffer>> call() async {
    return await _repository.fetchOffers();
  }
}
