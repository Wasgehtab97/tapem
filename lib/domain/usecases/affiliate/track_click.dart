// lib/domain/usecases/affiliate/track_click.dart

import 'package:tapem/domain/repositories/affiliate_repository.dart';

/// UseCase zum Tracken eines Klicks auf ein Affiliate-Angebot.
class TrackAffiliateClickUseCase {
  final AffiliateRepository _repository;

  TrackAffiliateClickUseCase(this._repository);

  /// Trackt den Klick für das Angebot mit der gegebenen [offerId].
  Future<void> call({required String offerId}) async {
    await _repository.trackClick(offerId);
  }
}
