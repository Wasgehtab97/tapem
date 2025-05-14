// lib/presentation/blocs/affiliate/affiliate_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'affiliate_event.dart';
import 'affiliate_state.dart';

import 'package:tapem/domain/usecases/affiliate/fetch_offers.dart'
    show FetchAffiliateOffersUseCase;
import 'package:tapem/domain/usecases/affiliate/track_click.dart'
    show TrackAffiliateClickUseCase;

/// Bloc für das Affiliate-Feature.
class AffiliateBloc extends Bloc<AffiliateEvent, AffiliateState> {
  final FetchAffiliateOffersUseCase _fetchOffers;
  final TrackAffiliateClickUseCase _trackClick;

  AffiliateBloc({
    required FetchAffiliateOffersUseCase fetchOffers,
    required TrackAffiliateClickUseCase trackClick,
  })  : _fetchOffers = fetchOffers,
        _trackClick = trackClick,
        super(const AffiliateLoading()) {
    on<AffiliateLoadOffers>(_onLoadOffers);
    on<AffiliateTrackClick>(_onTrackClick);
  }

  Future<void> _onLoadOffers(
    AffiliateLoadOffers event,
    Emitter<AffiliateState> emit,
  ) async {
    emit(const AffiliateLoading());
    try {
      final offers = await _fetchOffers.call();
      emit(AffiliateLoaded(offers));
    } catch (e) {
      emit(AffiliateError(e.toString()));
    }
  }

  Future<void> _onTrackClick(
    AffiliateTrackClick event,
    Emitter<AffiliateState> emit,
  ) async {
    try {
      // UseCase erwartet jetzt einen benannten Parameter:
      await _trackClick.call(offerId: event.offerId);
    } catch (e) {
      emit(AffiliateError('Fehler beim Tracken: ${e.toString()}'));
    }
  }
}
