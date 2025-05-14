// lib/presentation/blocs/affiliate/affiliate_state.dart

import 'package:equatable/equatable.dart';
import 'package:tapem/domain/models/affiliate_offer.dart';

abstract class AffiliateState extends Equatable {
  const AffiliateState();

  @override
  List<Object?> get props => [];
}

class AffiliateLoading extends AffiliateState {
  const AffiliateLoading();
}

class AffiliateLoaded extends AffiliateState {
  final List<AffiliateOffer> offers;
  const AffiliateLoaded(this.offers);

  @override
  List<Object?> get props => [offers];
}

class AffiliateError extends AffiliateState {
  final String message;
  const AffiliateError(this.message);

  @override
  List<Object?> get props => [message];
}
