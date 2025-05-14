import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc() : super(SplashInitial()) {
    on<SplashInitialize>(_onInitialize);
  }

  Future<void> _onInitialize(
    SplashInitialize event,
    Emitter<SplashState> emit,
  ) async {
    emit(SplashLoading());
    final prefs = await SharedPreferences.getInstance();
    // Hier Dein Logik: z.B. bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final hasToken = prefs.getString('authToken')?.isNotEmpty == true;
    final next = hasToken ? '/dashboard' : '/auth';
    // Kleiner Delay, damit der Spinner sichtbar bleibt:
    await Future.delayed(const Duration(milliseconds: 500));
    emit(SplashNavigate(next));
  }
}
