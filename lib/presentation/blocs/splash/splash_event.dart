part of 'splash_bloc.dart';

abstract class SplashEvent {}

/// Startet die Initialisierung (Laden der SharedPreferences o. Ä.).
class SplashInitialize extends SplashEvent {}
