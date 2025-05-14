part of 'splash_bloc.dart';

abstract class SplashState {}

/// Noch nichts passiert.
class SplashInitial extends SplashState {}

/// Wir laden gerade (z. B. SharedPreferences).
class SplashLoading extends SplashState {}

/// Navigationsbefehl zur nächsten Route.
class SplashNavigate extends SplashState {
  final String nextRoute;
  SplashNavigate(this.nextRoute);
}
