import '../../../bootstrap/providers.dart';
import '../../../core/providers/auth_provider.dart';

enum SplashDestination { auth, selectGym, home }

SplashDestination? resolveSplashDestination(AuthViewState state) {
  if (state.isLoading || (state.hasError && !state.isLoggedIn)) {
    return null;
  }
  if (!state.isLoggedIn) {
    return SplashDestination.auth;
  }
  if (state.gymContextStatus == GymContextStatus.ready) {
    return SplashDestination.home;
  }
  return SplashDestination.selectGym;
}
