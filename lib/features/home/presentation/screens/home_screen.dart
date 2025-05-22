// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tapem/core/providers/auth_provider.dart' as auth;
import 'package:tapem/core/providers/app_provider.dart'  as app;

import 'package:tapem/features/gym/presentation/screens/gym_screen.dart';
import 'package:tapem/features/profile/presentation/screens/profile_screen.dart';
import 'package:tapem/features/report/presentation/screens/report_dashboard_screen.dart';
import 'package:tapem/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:tapem/features/affiliate/presentation/screens/affiliate_screen.dart';
import 'package:tapem/app_router.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  // Nicht const, weil die einzelnen Screens nicht alle const-Konstruktoren haben
  static final List<Widget> _pages = [
    GymScreen(),
    ProfileScreen(),
    ReportDashboardScreen(),
    AdminDashboardScreen(),
    AffiliateScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<auth.AuthProvider>();
    final appProv  = context.read<app.AppProvider>();
    final user     = authProv.userEmail ?? 'Gast';

    return Scaffold(
      appBar: AppBar(
        title: Text('Willkommen, $user'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Abmelden',
            onPressed: () {
              authProv.logout();
              appProv.logout();
              Navigator.of(context)
                  .pushReplacementNamed(AppRouter.auth);
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Gym',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Affiliate',
          ),
        ],
      ),
    );
  }
}
