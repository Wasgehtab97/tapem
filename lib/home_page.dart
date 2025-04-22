// lib/screens/home_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/profile.dart';
import 'screens/report_dashboard.dart';
import 'screens/admin_dashboard.dart';
import 'screens/coach_dashboard.dart';
import 'screens/affiliate_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String? _role;
  bool _loaded = false;

  // Seiten für normale Nutzer
  static const _userPages = <Widget>[
    ProfileScreen(),
    AffiliateScreen(),
  ];

  // Seiten für Coaches (nur coach-Role)
  static const _coachPages = <Widget>[
    ProfileScreen(),
    AffiliateScreen(),
    CoachDashboardScreen(),
  ];

  // Seiten für Admins (admin-Role), inkl. Coach-Page
  static const _adminPages = <Widget>[
    ProfileScreen(),
    ReportDashboardScreen(),
    AffiliateScreen(),
    CoachDashboardScreen(),      // neu hinzugefügt
    AdminDashboardScreen(),
  ];

  List<Widget> get _pages {
    switch (_role) {
      case 'admin':
        return _adminPages;
      case 'coach':
        return _coachPages;
      default:
        return _userPages;
    }
  }

  List<BottomNavigationBarItem> get _items {
    if (_role == 'admin') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reporting'),
        BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'Deals'),
        BottomNavigationBarItem(icon: Icon(Icons.supervisor_account), label: 'Coach'),
        BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
      ];
    }
    if (_role == 'coach') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'Deals'),
        BottomNavigationBarItem(icon: Icon(Icons.supervisor_account), label: 'Coach'),
      ];
    }
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'Deals'),
    ];
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _role = prefs.getString('role');
        _loaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Falls CurrentIndex außerhalb liegt, zurücksetzen
    if (_currentIndex >= _pages.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: _items,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
