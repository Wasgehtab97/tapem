import 'package:tapem/domain/models/affiliate_offer.dart';
import 'package:tapem/domain/repositories/affiliate_repository.dart';
import 'package:tapem/data/sources/affiliate/firestore_affiliate_source.dart';


class AffiliateRepositoryImpl implements AffiliateRepository {
  final FirestoreAffiliateSource _source;
  AffiliateRepositoryImpl({FirestoreAffiliateSource? source})
      : _source = source ?? FirestoreAffiliateSource();

  @override
  Future<List<AffiliateOffer>> fetchOffers() async {
    final docs = await _source.fetchOffers();
    return docs.map((doc) {
      return AffiliateOffer.fromMap(
        doc.data(),
        id: doc.id,
      );
    }).toList();
  }

  @override
  Future<void> trackClick(String offerId) =>
      _source.trackClick(offerId);
}
