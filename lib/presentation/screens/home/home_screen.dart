import 'package:flutter/material.dart';
import 'package:tapem/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:tapem/presentation/screens/history/history_screen.dart';
import 'package:tapem/presentation/screens/profile/profile_screen.dart';
import 'package:tapem/presentation/screens/report/report_dashboard_screen.dart';
import 'package:tapem/presentation/screens/admin/admin_dashboard_screen.dart';

/// Einfache Bottom-TabBar mit allen Haupt-Screens.
/// Später kannst du hier bei Bedarf auf deine echten Widgets verweisen.
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const List<Widget> _tabs = [
    DashboardScreen(),
    HistoryScreen(),
    ProfileScreen(),
    ReportDashboardScreen(),
    AdminDashboardScreen(),
  ];

  static const List<BottomNavigationBarItem> _items = [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reports'),
    BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: _items,
        type: BottomNavigationBarType.fixed,
        onTap: (idx) => setState(() => _currentIndex = idx),
      ),
    );
  }
}
