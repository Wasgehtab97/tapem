// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/features/gym/presentation/screens/gym_screen.dart';
import 'package:tapem/features/profile/presentation/screens/profile_screen.dart';
import 'package:tapem/features/muscle_group/presentation/screens/muscle_group_screen_new.dart';
import 'package:tapem/features/report/presentation/screens/report_screen.dart';
import 'package:tapem/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:tapem/features/affiliate/presentation/screens/affiliate_screen.dart';
import 'package:tapem/features/rank/presentation/screens/rank_screen.dart';
import 'package:tapem/features/training_plan/presentation/screens/plan_overview_screen.dart';
import 'package:tapem/features/auth/presentation/widgets/username_dialog.dart';
import 'package:tapem/core/config/feature_flags.dart';
import 'package:tapem/features/nfc/widgets/nfc_scan_button.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/timer/timer_app_bar_title.dart';
import 'package:tapem/core/widgets/brand_gradient_text.dart';

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
    final loc = AppLocalizations.of(context)!;

    return [
      _TabInfo(
        const GymScreen(key: PageStorageKey('Gym')),
        BottomNavigationBarItem(
          icon: const Icon(Icons.fitness_center),
          label: loc.gymTitle,
        ),
      ),
      _TabInfo(
        const ProfileScreen(key: PageStorageKey('Profile')),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: loc.profileTitle,
        ),
      ),
      _TabInfo(
        const ReportScreen(key: PageStorageKey('Report')),
        BottomNavigationBarItem(
          icon: const Icon(Icons.insert_chart),
          label: loc.reportTitle,
        ),
      ),
      _TabInfo(
        const MuscleGroupScreenNew(key: PageStorageKey('Muskeln')),
        BottomNavigationBarItem(
          icon: const Icon(Icons.accessibility_new),
          label: loc.muscleGroupTitle,
        ),
      ),
      _TabInfo(
        const AdminDashboardScreen(key: PageStorageKey('Admin')),
        BottomNavigationBarItem(
          icon: const Icon(Icons.admin_panel_settings),
          label: loc.homeTabAdmin,
        ),
      ),
      _TabInfo(
        RankScreen(
            key: const PageStorageKey('Rank'),
            gymId: gymId,
            deviceId: deviceId),
        BottomNavigationBarItem(
          icon: const Icon(Icons.leaderboard),
          label: loc.homeTabRank,
        ),
      ),
      _TabInfo(
        const AffiliateScreen(key: PageStorageKey('Affiliate')),
        BottomNavigationBarItem(
          icon: const Icon(Icons.group),
          label: loc.homeTabAffiliate,
        ),
      ),
      _TabInfo(
        const PlanOverviewScreen(key: PageStorageKey('Plaene')),
        BottomNavigationBarItem(
          icon: const Icon(Icons.event_note),
          label: loc.homeTabPlans,
        ),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    // Nach Login Gym laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProv = context.read<AuthProvider>();
      debugPrint('[Tabs] role=${authProv.role}, isAdmin=${authProv.isAdmin}, restricted=${FF.limitTabsForMembers}');
      final gymProv = context.read<GymProvider>();
      final code = authProv.gymCode;
      if (code != null && code.isNotEmpty) {
        gymProv.loadGymData(code);
      }
      if (authProv.userName == null || authProv.userName!.isEmpty) {
        showUsernameDialog(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthProvider, bool>((a) => a.isAdmin);
    final allTabs = _buildTabs(context);
    final tabs = (FF.limitTabsForMembers && !isAdmin)
        ? [allTabs[0], allTabs[1], allTabs[5]]
        : allTabs;
    if (_currentIndex >= tabs.length) {
      _currentIndex = 0;
    }
    final currentTab = tabs[_currentIndex];
    final currentLabel = currentTab.item.label ?? '';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        centerTitle: true,
        leadingWidth: kToolbarHeight + 8,
        leading: const SizedBox(width: kToolbarHeight + 8),
        title: _buildAppBarTitle(context, currentLabel),
        actions: const [
          NfcScanButton(),
          SizedBox(width: 8),
        ],
      ),
      body: currentTab.page,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [for (final t in tabs) t.item],
      ),
    );
  }

  Widget _buildAppBarTitle(BuildContext context, String currentLabel) {
    final loc = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();

    switch (_currentIndex) {
      case 0:
        return TimerAppBarTitle(
          title: BrandGradientText(
            loc.gymTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      case 1:
        final username = auth.userName ?? auth.userEmail ?? loc.profileTitle;
        return TimerAppBarTitle(
          title: BrandGradientText(
            username,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      default:
        final resolvedLabel = currentLabel.isNotEmpty ? currentLabel : loc.appTitle;
        return TimerAppBarTitle(
          title: BrandGradientText(
            resolvedLabel,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
    }
  }
}

class _TabInfo {
  final Widget page;
  final BottomNavigationBarItem item;
  const _TabInfo(this.page, this.item);
}
