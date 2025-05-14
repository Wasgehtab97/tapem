// lib/presentation/blocs/affiliate/affiliate_event.dart

import 'package:equatable/equatable.dart';

abstract class AffiliateEvent extends Equatable {
  const AffiliateEvent();

  @override
  List<Object?> get props => [];
}

class AffiliateLoadOffers extends AffiliateEvent {
  const AffiliateLoadOffers();
}

class AffiliateTrackClick extends AffiliateEvent {
  final String offerId;
  const AffiliateTrackClick(this.offerId);

  @override
  List<Object?> get props => [offerId];
}
