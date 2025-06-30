// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/core/providers/report_provider.dart';
import 'package:tapem/features/gym/presentation/screens/gym_screen.dart';
import 'package:tapem/features/profile/presentation/screens/profile_screen.dart';
import 'package:tapem/features/report/presentation/screens/report_screen.dart';
import 'package:tapem/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:tapem/features/affiliate/presentation/screens/affiliate_screen.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/features/rank/presentation/screens/rank_screen.dart';
import 'package:tapem/features/training_plan/presentation/screens/plan_overview_screen.dart';
import 'package:tapem/features/auth/presentation/widgets/username_dialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  List<Widget> _buildPages(BuildContext context) {
    final gymId = context.watch<GymProvider>().currentGymId;
    return [
      const GymScreen(),
      const ProfileScreen(),
      const ReportScreen(),
      const AdminDashboardScreen(),
      RankScreen(gymId: gymId),
      const AffiliateScreen(),
      const PlanOverviewScreen(),
    ];
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    // Nach Login Gym laden und Report triggern
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProv = context.read<AuthProvider>();
      final gymProv = context.read<GymProvider>();
      final reportProv = context.read<ReportProvider>();
      final code = authProv.gymCode;
      if (code != null && code.isNotEmpty) {
        gymProv.loadGymData(code).then((_) {
          final id = gymProv.currentGymId;
          reportProv.loadReport(id);
        });
      }
      if (authProv.userName == null || authProv.userName!.isEmpty) {
        showUsernameDialog(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final loc = AppLocalizations.of(context)!;
    final userDisplay = authProv.userName ?? authProv.userEmail ?? loc.genericUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.homeWelcome(userDisplay)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushReplacementNamed(AppRouter.auth);
            },
          ),
        ],
      ),
      body: _buildPages(context)[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Gym',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Rank'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Affiliate'),
          BottomNavigationBarItem(icon: Icon(Icons.event_note), label: 'Pläne'),
        ],
      ),
    );
  }
}
