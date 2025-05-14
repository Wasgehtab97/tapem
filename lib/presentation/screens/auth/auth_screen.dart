// lib/presentation/screens/auth/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tapem/presentation/blocs/auth/auth_bloc.dart';
import 'package:tapem/presentation/blocs/auth/auth_event.dart';
import 'package:tapem/presentation/blocs/auth/auth_state.dart';

import 'package:tapem/domain/repositories/auth_repository.dart';
import 'package:tapem/domain/usecases/auth/get_saved_gym_id.dart';
import 'package:tapem/domain/usecases/auth/login.dart';
import 'package:tapem/domain/usecases/auth/register.dart';
import 'package:tapem/domain/usecases/auth/logout.dart';

import 'package:tapem/presentation/widgets/auth/login_form.dart';
import 'package:tapem/presentation/widgets/auth/registration_form.dart';

/// Kombinierte Login/Registration mit BLoC.
class AuthScreen extends StatelessWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (ctx) => AuthBloc(
        getSavedGymId: GetSavedGymIdUseCase(ctx.read<AuthRepository>()),
        login:       LoginUseCase(ctx.read<AuthRepository>()),
        register:    RegisterUseCase(ctx.read<AuthRepository>()),
        logout:      LogoutUseCase(ctx.read<AuthRepository>()),
      )..add(AuthCheckStatus()),
      child: const _AuthView(),
    );
  }
}

class _AuthView extends StatelessWidget {
  const _AuthView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is Authenticated) {
          // Nach erfolgreichem Login/Check direkt ins Dashboard
          Navigator.pushReplacementNamed(ctx, '/dashboard');
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (ctx, state) {
          if (state is AuthInitial || state is AuthLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Anmelden / Registrieren'),
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Login'),
                    Tab(text: 'Register'),
                  ],
                ),
              ),
              body: const TabBarView(
                children: [
                  LoginForm(),
                  RegistrationForm(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
