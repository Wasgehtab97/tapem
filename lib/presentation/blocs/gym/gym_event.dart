abstract class GymEvent {}

/// Fordert das Laden aller Geräte an, optional mit Namensfilter.
class GymFetchDevices extends GymEvent {
  final String? nameQuery;

  GymFetchDevices({this.nameQuery});
}
