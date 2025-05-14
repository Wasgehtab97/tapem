// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme
import 'core/theme/theme_loader.dart';

// Data Sources
import 'data/sources/auth/firestore_auth_source.dart';
import 'data/sources/coach/firestore_coach_source.dart';
import 'data/sources/tenant/firestore_tenant_source.dart';
import 'data/sources/dashboard/firestore_dashboard_source.dart';
import 'data/sources/device/firestore_device_source.dart';
import 'data/sources/admin/firestore_admin_source.dart';
import 'data/sources/affiliate/firestore_affiliate_source.dart';
import 'data/sources/gym/firestore_gym_source.dart';
import 'data/sources/history/firestore_history_source.dart';
import 'data/sources/profile/firestore_profile_source.dart';
import 'data/sources/rank/firestore_rank_source.dart';
import 'data/sources/report/firestore_report_source.dart';
import 'data/sources/training_details/firestore_training_details_source.dart';
// Alias, um Konflikt mit Repository-Impl zu vermeiden:
import 'data/sources/training_plan/firestore_training_plan_source.dart' as tp_src;

// Repository-Implementierungen
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/coach_repository_impl.dart';
import 'data/repositories/tenant_repository_impl.dart';
import 'data/repositories/report_repository_impl.dart';
import 'data/repositories/dashboard_repository_impl.dart';
import 'data/repositories/device_repository_impl.dart';
import 'data/repositories/admin_repository_impl.dart';
import 'data/repositories/affiliate_repository_impl.dart';
import 'data/repositories/gym_repository_impl.dart';
import 'data/repositories/history_repository_impl.dart';
import 'data/repositories/profile_repository_impl.dart';
import 'data/repositories/rank_repository_impl.dart';
import 'data/repositories/training_details_repository_impl.dart';
// Impl der Trainingsplan-Schicht:
import 'data/repositories/training_plan_repository_impl.dart';

// Domain-Interfaces
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/coach_repository.dart';
import 'domain/repositories/tenant_repository.dart';
import 'domain/repositories/report_repository.dart';
import 'domain/repositories/dashboard_repository.dart';
import 'domain/repositories/device_repository.dart';
import 'domain/repositories/admin_repository.dart';
import 'domain/repositories/affiliate_repository.dart';
import 'domain/repositories/gym_repository.dart';
import 'domain/repositories/history_repository.dart';
import 'domain/repositories/profile_repository.dart';
import 'domain/repositories/rank_repository.dart';
import 'domain/repositories/training_details_repository.dart';
import 'domain/repositories/training_plan_repository.dart';

// Use Cases (Auth)
import 'domain/usecases/auth/login.dart';
import 'domain/usecases/auth/register.dart';
import 'domain/usecases/auth/logout.dart';
import 'domain/usecases/auth/get_saved_gym_id.dart' as auth_uc show GetSavedGymIdUseCase;
// Use Cases (Coach)
import 'domain/usecases/coach/fetch_training_dates.dart';
import 'domain/usecases/coach/load_clients.dart';
import 'domain/usecases/coach/send_request.dart' as coach_uc show SendCoachingRequestUseCase;
// Use Cases (Tenant)
import 'domain/usecases/tenant/fetch_all_tenants.dart';
import 'domain/usecases/tenant/get_saved_gym_id.dart' as tenant_uc show GetSavedGymIdUseCase;
import 'domain/usecases/tenant/get_config.dart';
import 'domain/usecases/tenant/switch_tenant.dart';
// Use Cases (Report)
import 'domain/usecases/report/fetch_devices.dart';
import 'domain/usecases/report/fetch_report_data.dart';
// Use Cases (Dashboard)
import 'domain/usecases/dashboard/load_device.dart';
import 'domain/usecases/dashboard/add_set.dart';
import 'domain/usecases/dashboard/finish_session.dart';
// Use Cases (Device)
import 'domain/usecases/device/load_devices.dart';
import 'domain/usecases/device/register_device.dart';
import 'domain/usecases/device/update_device.dart' as device_uc show UpdateDeviceUseCase;
// Use Cases (Admin)
import 'domain/usecases/admin/create_device.dart';
import 'domain/usecases/admin/fetch_devices.dart';
import 'domain/usecases/admin/update_device.dart' as admin_uc show UpdateDeviceUseCase;
// Use Cases (Affiliate)
import 'domain/usecases/affiliate/fetch_offers.dart';
import 'domain/usecases/affiliate/track_click.dart';
// Use Cases (Gym)
import 'domain/usecases/gym/fetch_devices.dart';
// Use Cases (History)
import 'domain/usecases/history/fetch_history.dart';
import 'domain/usecases/history/get_current_user_id.dart' show GetCurrentUserIdHistoryUseCase;
// Use Cases (Profile)
import 'domain/usecases/profile/get_current_user_id.dart' show GetCurrentUserIdProfileUseCase;
import 'domain/usecases/profile/fetch_user_profile.dart';
import 'domain/usecases/profile/fetch_training_dates.dart' show FetchProfileTrainingDatesUseCase;
import 'domain/usecases/profile/fetch_pending_request.dart';
import 'domain/usecases/profile/respond_request.dart';
import 'domain/usecases/profile/sign_out.dart';
// Use Cases (Rank)
import 'domain/usecases/rank/fetch_all_users.dart';
// Use Cases (Training Details)
import 'domain/usecases/training_details/fetch_details.dart';
import 'domain/usecases/training_details/get_current_user_id.dart' show GetCurrentUserIdDetailsUseCase;
// Use Cases (Training Plan)
import 'domain/usecases/training_plan/load_plans.dart';
import 'domain/usecases/training_plan/create_plan.dart';
import 'domain/usecases/training_plan/delete_plan.dart';
import 'domain/usecases/training_plan/load_plan_by_id.dart';
import 'domain/usecases/training_plan/start_plan.dart';
import 'domain/usecases/training_plan/update_plan.dart';

// Blocs & Events
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/coach/coach_bloc.dart';
import 'presentation/blocs/tenant/tenant_bloc.dart';
import 'presentation/blocs/tenant/tenant_event.dart';
import 'presentation/blocs/report/report_bloc.dart';
import 'presentation/blocs/dashboard/dashboard_bloc.dart';
import 'presentation/blocs/device/device_bloc.dart';
import 'presentation/blocs/admin/admin_bloc.dart';
import 'presentation/blocs/affiliate/affiliate_bloc.dart';
import 'presentation/blocs/affiliate/affiliate_event.dart';
import 'presentation/blocs/gym/gym_bloc.dart';
import 'presentation/blocs/gym/gym_event.dart';
import 'presentation/blocs/history/history_bloc.dart';
import 'presentation/blocs/history/history_event.dart';
import 'presentation/blocs/profile/profile_bloc.dart';
import 'presentation/blocs/profile/profile_event.dart';
import 'presentation/blocs/rank/rank_bloc.dart';
import 'presentation/blocs/rank/rank_event.dart';
import 'presentation/blocs/training_details/training_details_bloc.dart';
import 'presentation/blocs/training_details/training_details_event.dart';
import 'presentation/blocs/training_plan/training_plan_bloc.dart';
import 'presentation/blocs/training_plan/training_plan_event.dart';

// Screens
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/auth/auth_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/history/history_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/report/report_dashboard_screen.dart';
import 'presentation/screens/admin/admin_dashboard_screen.dart';
import 'presentation/screens/training_plan/trainingsplan_screen.dart';
import 'presentation/screens/gym/gym_screen.dart';
import 'presentation/screens/rank/rank_screen.dart';
import 'presentation/screens/affiliate/affiliate_screen.dart';
import 'presentation/screens/coach/coach_dashboard_screen.dart';
import 'presentation/screens/device/device_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(
    fileName: const bool.fromEnvironment('dart.vm.product')
        ? '.env.prod'
        : '.env.dev',
  );
  await Firebase.initializeApp();
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);
  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiRepositoryProvider(
      providers: [
        // --- Auth ---
        RepositoryProvider<AuthRepository>(
          create: (_) => AuthRepositoryImpl(source: FirestoreAuthSource()),
        ),
        RepositoryProvider<LoginUseCase>(
          create: (ctx) => LoginUseCase(ctx.read<AuthRepository>()),
        ),
        RepositoryProvider<RegisterUseCase>(
          create: (ctx) => RegisterUseCase(ctx.read<AuthRepository>()),
        ),
        RepositoryProvider<LogoutUseCase>(
          create: (ctx) => LogoutUseCase(ctx.read<AuthRepository>()),
        ),
        RepositoryProvider<auth_uc.GetSavedGymIdUseCase>(
          create: (ctx) =>
              auth_uc.GetSavedGymIdUseCase(ctx.read<AuthRepository>()),
        ),

        // --- Coach ---
        RepositoryProvider<CoachRepository>(
          create: (_) =>
              CoachRepositoryImpl(source: FirestoreCoachSource()),
        ),
        RepositoryProvider<FetchTrainingDatesUseCase>(
          create: (ctx) =>
              FetchTrainingDatesUseCase(ctx.read<CoachRepository>()),
        ),
        RepositoryProvider<LoadClientsUseCase>(
          create: (ctx) => LoadClientsUseCase(ctx.read<CoachRepository>()),
        ),
        RepositoryProvider<coach_uc.SendCoachingRequestUseCase>(
          create: (ctx) => coach_uc.SendCoachingRequestUseCase(
              ctx.read<CoachRepository>()),
        ),

        // --- Tenant ---
        RepositoryProvider<TenantRepository>(
          create: (_) =>
              TenantRepositoryImpl(FirebaseFirestore.instance, prefs),
        ),
        RepositoryProvider<FetchAllTenantsUseCase>(
          create: (ctx) =>
              FetchAllTenantsUseCase(ctx.read<TenantRepository>()),
        ),
        RepositoryProvider<tenant_uc.GetSavedGymIdUseCase>(
          create: (ctx) =>
              tenant_uc.GetSavedGymIdUseCase(ctx.read<TenantRepository>()),
        ),
        RepositoryProvider<GetGymConfigUseCase>(
          create: (ctx) => GetGymConfigUseCase(ctx.read<TenantRepository>()),
        ),
        RepositoryProvider<SwitchTenantUseCase>(
          create: (ctx) => SwitchTenantUseCase(ctx.read<TenantRepository>()),
        ),

        // --- Report ---
        RepositoryProvider<ReportRepository>(
          create: (_) =>
              ReportRepositoryImpl(source: FirestoreReportSource()),
        ),
        RepositoryProvider<FetchReportDevicesUseCase>(
          create: (ctx) =>
              FetchReportDevicesUseCase(ctx.read<ReportRepository>()),
        ),
        RepositoryProvider<FetchReportDataUseCase>(
          create: (ctx) =>
              FetchReportDataUseCase(ctx.read<ReportRepository>()),
        ),

        // --- Dashboard ---
        RepositoryProvider<DashboardRepository>(
          create: (_) =>
              DashboardRepositoryImpl(source: FirestoreDashboardSource()),
        ),
        RepositoryProvider<LoadDeviceUseCase>(
          create: (ctx) =>
              LoadDeviceUseCase(ctx.read<DashboardRepository>()),
        ),
        RepositoryProvider<AddSetUseCase>(
          create: (ctx) => AddSetUseCase(ctx.read<DashboardRepository>()),
        ),
        RepositoryProvider<FinishSessionUseCase>(
          create: (ctx) =>
              FinishSessionUseCase(ctx.read<DashboardRepository>()),
        ),

        // --- Device ---
        RepositoryProvider<DeviceRepository>(
          create: (_) =>
              DeviceRepositoryImpl(source: FirestoreDeviceSource()),
        ),
        RepositoryProvider<LoadDevicesUseCase>(
          create: (ctx) => LoadDevicesUseCase(ctx.read<DeviceRepository>()),
        ),
        RepositoryProvider<RegisterDeviceUseCase>(
          create: (ctx) =>
              RegisterDeviceUseCase(ctx.read<DeviceRepository>()),
        ),
        RepositoryProvider<device_uc.UpdateDeviceUseCase>(
          create: (ctx) =>
              device_uc.UpdateDeviceUseCase(ctx.read<DeviceRepository>()),
        ),

        // --- Admin ---
        RepositoryProvider<AdminRepository>(
          create: (_) =>
              AdminRepositoryImpl(source: FirestoreAdminSource()),
        ),
        RepositoryProvider<CreateDeviceUseCase>(
          create: (ctx) => CreateDeviceUseCase(ctx.read<AdminRepository>()),
        ),
        RepositoryProvider<FetchDevicesUseCase>(
          create: (ctx) => FetchDevicesUseCase(ctx.read<AdminRepository>()),
        ),
        RepositoryProvider<admin_uc.UpdateDeviceUseCase>(
          create: (ctx) =>
              admin_uc.UpdateDeviceUseCase(ctx.read<AdminRepository>()),
        ),

        // --- Affiliate ---
        RepositoryProvider<AffiliateRepository>(
          create: (_) =>
              AffiliateRepositoryImpl(source: FirestoreAffiliateSource()),
        ),
        RepositoryProvider<FetchAffiliateOffersUseCase>(
          create: (ctx) =>
              FetchAffiliateOffersUseCase(ctx.read<AffiliateRepository>()),
        ),
        RepositoryProvider<TrackAffiliateClickUseCase>(
          create: (ctx) =>
              TrackAffiliateClickUseCase(ctx.read<AffiliateRepository>()),
        ),

        // --- Gym ---
        RepositoryProvider<GymRepository>(
          create: (_) => GymRepositoryImpl(source: FirestoreGymSource()),
        ),
        RepositoryProvider<FetchGymDevicesUseCase>(
          create: (ctx) => FetchGymDevicesUseCase(ctx.read<GymRepository>()),
        ),

        // --- History ---
        RepositoryProvider<HistoryRepository>(
          create: (_) =>
              HistoryRepositoryImpl(source: FirestoreHistorySource()),
        ),
        RepositoryProvider<FetchHistoryUseCase>(
          create: (ctx) =>
              FetchHistoryUseCase(ctx.read<HistoryRepository>()),
        ),
        RepositoryProvider<GetCurrentUserIdHistoryUseCase>(
          create: (ctx) => GetCurrentUserIdHistoryUseCase(
              ctx.read<HistoryRepository>()),
        ),

        // --- Profile ---
        RepositoryProvider<ProfileRepository>(
          create: (_) =>
              ProfileRepositoryImpl(source: FirestoreProfileSource()),
        ),
        RepositoryProvider<FetchPendingRequestUseCase>(
          create: (ctx) =>
              FetchPendingRequestUseCase(ctx.read<ProfileRepository>()),
        ),
        RepositoryProvider<FetchProfileTrainingDatesUseCase>(
          create: (ctx) => FetchProfileTrainingDatesUseCase(
              ctx.read<ProfileRepository>()),
        ),
        RepositoryProvider<RespondRequestUseCase>(
          create: (ctx) =>
              RespondRequestUseCase(ctx.read<ProfileRepository>()),
        ),
        RepositoryProvider<FetchUserProfileUseCase>(
          create: (ctx) =>
              FetchUserProfileUseCase(ctx.read<ProfileRepository>()),
        ),
        RepositoryProvider<GetCurrentUserIdProfileUseCase>(
          create: (ctx) => GetCurrentUserIdProfileUseCase(
              ctx.read<ProfileRepository>()),
        ),
        RepositoryProvider<SignOutUseCase>(
          create: (ctx) => SignOutUseCase(ctx.read<ProfileRepository>()),
        ),

        // --- Rank ---
        RepositoryProvider<RankRepository>(
          create: (_) =>
              RankRepositoryImpl(source: FirestoreRankSource()),
        ),
        RepositoryProvider<FetchAllUsersUseCase>(
          create: (ctx) =>
              FetchAllUsersUseCase(ctx.read<RankRepository>()),
        ),

        // --- Training Details ---
        RepositoryProvider<TrainingDetailsRepository>(
          create: (_) => TrainingDetailsRepositoryImpl(
              source: FirestoreTrainingDetailsSource()),
        ),
        RepositoryProvider<FetchTrainingDetailsUseCase>(
          create: (ctx) => FetchTrainingDetailsUseCase(
              ctx.read<TrainingDetailsRepository>()),
        ),
        RepositoryProvider<GetCurrentUserIdDetailsUseCase>(
          create: (ctx) => GetCurrentUserIdDetailsUseCase(
              ctx.read<TrainingDetailsRepository>()),
        ),

        // --- Training Plan ---
        RepositoryProvider<TrainingPlanRepository>(
          create: (_) => TrainingPlanRepositoryImpl(
              tp_src.FirestoreTrainingPlanSource()),
        ),
        RepositoryProvider<LoadPlansUseCase>(
          create: (ctx) =>
              LoadPlansUseCase(ctx.read<TrainingPlanRepository>()),
        ),
        RepositoryProvider<CreatePlanUseCase>(
          create: (ctx) =>
              CreatePlanUseCase(ctx.read<TrainingPlanRepository>()),
        ),
        RepositoryProvider<DeletePlanUseCase>(
          create: (ctx) =>
              DeletePlanUseCase(ctx.read<TrainingPlanRepository>()),
        ),
        RepositoryProvider<LoadPlanByIdUseCase>(
          create: (ctx) =>
              LoadPlanByIdUseCase(ctx.read<TrainingPlanRepository>()),
        ),
        RepositoryProvider<StartPlanUseCase>(
          create: (ctx) =>
              StartPlanUseCase(ctx.read<TrainingPlanRepository>()),
        ),
        RepositoryProvider<UpdatePlanUseCase>(
          create: (ctx) =>
              UpdatePlanUseCase(ctx.read<TrainingPlanRepository>()),
        ),
      ],
      child: const BlocProvidersRoot(),
    ),
  );
}

class BlocProvidersRoot extends StatelessWidget {
  const BlocProvidersRoot({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: context.read<auth_uc.GetSavedGymIdUseCase>().call(),
      builder: (ctx, snap) {
        final gymId = snap.data ?? '';
        return MultiBlocProvider(
          providers: [
            // --- AuthBloc ---
            BlocProvider<AuthBloc>(
              create: (ctx) => AuthBloc(
                getSavedGymId: ctx.read<auth_uc.GetSavedGymIdUseCase>(),
                login: ctx.read<LoginUseCase>(),
                register: ctx.read<RegisterUseCase>(),
                logout: ctx.read<LogoutUseCase>(),
              ),
            ),

            // --- CoachBloc ---
            BlocProvider<CoachBloc>(
              create: (ctx) => CoachBloc(
                loadClients: ctx.read<LoadClientsUseCase>(),
                fetchDates: ctx.read<FetchTrainingDatesUseCase>(),
                sendRequest:
                    ctx.read<coach_uc.SendCoachingRequestUseCase>(),
              ),
            ),

            // --- TenantBloc ---
            BlocProvider<TenantBloc>(
              create: (ctx) => TenantBloc(
                getSavedGymId:
                    ctx.read<tenant_uc.GetSavedGymIdUseCase>(),
                getGymConfig: ctx.read<GetGymConfigUseCase>(),
                switchTenant: ctx.read<SwitchTenantUseCase>(),
              )..add(TenantLoad()),
            ),

            // --- ReportBloc ---
            BlocProvider<ReportBloc>(
              create: (ctx) => ReportBloc(
                fetchData: ctx.read<FetchReportDataUseCase>(),
              ),
            ),

            // --- DashboardBloc ---
            BlocProvider<DashboardBloc>(
              create: (ctx) => DashboardBloc(
                loadDevice: ctx.read<LoadDeviceUseCase>(),
                addSet: ctx.read<AddSetUseCase>(),
                finishSession:
                    ctx.read<FinishSessionUseCase>(),
              ),
            ),

            // --- DeviceBloc ---
            BlocProvider<DeviceBloc>(
              create: (ctx) => DeviceBloc(
                loadAll: ctx.read<LoadDevicesUseCase>(),
                registerUseCase:
                    ctx.read<RegisterDeviceUseCase>(),
                updateUseCase:
                    ctx.read<device_uc.UpdateDeviceUseCase>(),
              ),
            ),

            // --- AdminBloc ---
            BlocProvider<AdminBloc>(
              create: (ctx) => AdminBloc(
                fetchDevices: ctx.read<FetchDevicesUseCase>(),
                createDevice: ctx.read<CreateDeviceUseCase>(),
                updateDevice:
                    ctx.read<admin_uc.UpdateDeviceUseCase>(),
              ),
            ),

            // --- AffiliateBloc ---
            BlocProvider<AffiliateBloc>(
              create: (ctx) => AffiliateBloc(
                fetchOffers:
                    ctx.read<FetchAffiliateOffersUseCase>(),
                trackClick:
                    ctx.read<TrackAffiliateClickUseCase>(),
              )..add(const AffiliateLoadOffers()),
            ),

            // --- GymBloc ---
            BlocProvider<GymBloc>(
              create: (ctx) => GymBloc(
                fetchUseCase:
                    ctx.read<FetchGymDevicesUseCase>(),  // <— korrigiert!
              )..add(GymFetchDevices(nameQuery: null)),
            ),

            // --- HistoryBloc ---
            BlocProvider<HistoryBloc>(
              create: (ctx) => HistoryBloc(
                getUserId:
                    ctx.read<GetCurrentUserIdHistoryUseCase>(),  // <— korrigiert!
                fetchHistory:
                    ctx.read<FetchHistoryUseCase>(),
              )..add(HistoryLoad(deviceId: '', exerciseFilter: null)),
            ),

            // --- ProfileBloc ---
            BlocProvider<ProfileBloc>(
              create: (ctx) => ProfileBloc(
                getUserId:
                    ctx.read<GetCurrentUserIdProfileUseCase>(),
                fetchUser:
                    ctx.read<FetchUserProfileUseCase>(),
                fetchDates:
                    ctx.read<FetchProfileTrainingDatesUseCase>(),
                fetchPending:
                    ctx.read<FetchPendingRequestUseCase>(),
                respond:
                    ctx.read<RespondRequestUseCase>(),
                signOut:
                    ctx.read<SignOutUseCase>(),
              )..add(ProfileLoadAll()),
            ),

            // --- RankBloc ---
            BlocProvider<RankBloc>(
              create: (ctx) => RankBloc(
                ctx.read<FetchAllUsersUseCase>(),
              )..add(RankLoadAll()),
            ),

            // --- TrainingDetailsBloc ---
            BlocProvider<TrainingDetailsBloc>(
              create: (ctx) => TrainingDetailsBloc(
                getCurrentUserId:
                    ctx.read<GetCurrentUserIdDetailsUseCase>(),
                fetchDetails:
                    ctx.read<FetchTrainingDetailsUseCase>(),
              )..add(TrainingDetailsLoad(DateTime.now().toIso8601String())),
            ),

            // --- TrainingPlanBloc ---
            BlocProvider<TrainingPlanBloc>(
              create: (ctx) => TrainingPlanBloc(
                loadPlans: ctx.read<LoadPlansUseCase>(),
                createPlan: ctx.read<CreatePlanUseCase>(),
                updatePlan: ctx.read<UpdatePlanUseCase>(),
                deletePlan: ctx.read<DeletePlanUseCase>(),
                startPlan: ctx.read<StartPlanUseCase>(),
                loadById: ctx.read<LoadPlanByIdUseCase>(),
              )..add(TrainingPlanLoadAll(gymId)),
            ),
          ],
          child: const TapemApp(),
        );
      },
    );
  }
}

class TapemApp extends StatelessWidget {
  const TapemApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ThemeData>(
      future: ThemeLoader.loadTheme(),
      builder: (ctx, snap) {
        final theme =
            snap.data ?? ThemeData.light().copyWith(useMaterial3: true);
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: dotenv.env['APP_NAME'] ?? "Tap'em",
          debugShowCheckedModeBanner: false,
          theme: theme,
          darkTheme: ThemeData.dark(),
          initialRoute: '/',
          routes: {
            '/': (_) => const SplashScreen(),
            '/auth': (_) => const AuthScreen(),
            '/dashboard': (_) => const DashboardScreen(),
            '/history': (_) => const HistoryScreen(),
            '/profile': (_) => const ProfileScreen(),
            '/report': (_) => const ReportDashboardScreen(),
            '/admin': (_) => const AdminDashboardScreen(),
            '/trainingsplan': (ctx) {
              final planId =
                  ModalRoute.of(ctx)!.settings.arguments as String;
              return TrainingsplanScreen(planId: planId);
            },
            '/gym': (_) => const GymScreen(),
            '/rank': (_) => const RankScreen(),
            '/affiliate': (_) => const AffiliateScreen(),
            '/coach': (_) => const CoachDashboardScreen(),
            '/device': (_) => const DeviceScreen(),
          },
          onUnknownRoute: (_) => MaterialPageRoute(
            builder: (_) => const DashboardScreen(),
          ),
        );
      },
    );
  }
}
