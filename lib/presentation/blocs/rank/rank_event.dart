import 'package:equatable/equatable.dart';

/// Events für den RankBloc.
abstract class RankEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Lädt alle Nutzer für die Rangliste.
class RankLoadAll extends RankEvent {}
