// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/core/providers/report_provider.dart';
import 'package:tapem/features/gym/presentation/screens/gym_screen.dart';
import 'package:tapem/features/profile/presentation/screens/profile_screen.dart';
import 'package:tapem/features/muscle_group/presentation/screens/muscle_group_screen_new.dart';
import 'package:tapem/features/report/presentation/screens/report_screen.dart';
import 'package:tapem/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:tapem/features/affiliate/presentation/screens/affiliate_screen.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/features/rank/presentation/screens/rank_screen.dart';
import 'package:tapem/features/training_plan/presentation/screens/plan_overview_screen.dart';
import 'package:tapem/features/auth/presentation/widgets/username_dialog.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/config/feature_flags.dart';
import 'package:tapem/core/widgets/workout_timer_button.dart';
import 'package:tapem/features/nfc/widgets/nfc_scan_button.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  List<_TabInfo> _buildTabs(BuildContext context) {
    final gymProv = context.watch<GymProvider>();
    final gymId = gymProv.currentGymId;
    final devices = gymProv.devices.where((d) => !d.isMulti).toList();
    final deviceId = devices.isNotEmpty ? devices.first.uid : '';

    return [
      _TabInfo(
        const GymScreen(key: PageStorageKey('Gym')),
        const BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center), label: 'Gym'),
      ),
      _TabInfo(
        const ProfileScreen(key: PageStorageKey('Profile')),
        const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ),
      _TabInfo(
        const ReportScreen(key: PageStorageKey('Report')),
        const BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart), label: 'Report'),
      ),
      _TabInfo(
        const MuscleGroupScreenNew(key: PageStorageKey('Muskeln')),
        const BottomNavigationBarItem(
            icon: Icon(Icons.accessibility_new), label: 'Muskeln'),
      ),
      _TabInfo(
        const AdminDashboardScreen(key: PageStorageKey('Admin')),
        const BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
      ),
      _TabInfo(
        RankScreen(
            key: const PageStorageKey('Rank'),
            gymId: gymId,
            deviceId: deviceId),
        const BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard), label: 'Rank'),
      ),
      _TabInfo(
        const AffiliateScreen(key: PageStorageKey('Affiliate')),
        const BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Affiliate'),
      ),
      _TabInfo(
        const PlanOverviewScreen(key: PageStorageKey('Plaene')),
        const BottomNavigationBarItem(
            icon: Icon(Icons.event_note), label: 'Pläne'),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    // Nach Login Gym laden und Report triggern
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProv = context.read<AuthProvider>();
      debugPrint('[Tabs] role=${authProv.role}, isAdmin=${authProv.isAdmin}, restricted=${FF.limitTabsForMembers}');
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
    final isAdmin = context.select<AuthProvider, bool>((a) => a.isAdmin);
    final loc = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final userDisplay =
        auth.userName ?? auth.userEmail ?? loc.genericUser;
    final allTabs = _buildTabs(context);
    final tabs = (FF.limitTabsForMembers && !isAdmin)
        ? [allTabs[0], allTabs[1], allTabs[5]]
        : allTabs;
    if (_currentIndex >= tabs.length) {
      _currentIndex = 0;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(userDisplay),
        actions: const [
          WorkoutTimerButton(),
          NfcScanButton(),
        ],
      ),
      body: tabs[_currentIndex].page,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [for (final t in tabs) t.item],
      ),
    );
  }
}

class _TabInfo {
  final Widget page;
  final BottomNavigationBarItem item;
  const _TabInfo(this.page, this.item);
}
