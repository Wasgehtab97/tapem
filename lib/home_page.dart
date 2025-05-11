// lib/home_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/profile.dart';
import 'screens/affiliate_screen.dart';
import 'screens/coach_dashboard.dart';
import 'screens/report_dashboard.dart';
import 'screens/admin_dashboard.dart';

/// HomePage mit BottomNavigation je nach User-Rolle.
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String? _role;
  bool _loaded = false;

  static const _userPages = <Widget>[
    ProfileScreen(),
    AffiliateScreen(),
  ];

  static const _coachPages = <Widget>[
    ProfileScreen(),
    AffiliateScreen(),
    CoachDashboardScreen(),
  ];

  static const _adminPages = <Widget>[
    ProfileScreen(),
    ReportDashboardScreen(),
    AffiliateScreen(),
    CoachDashboardScreen(),
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
    switch (_role) {
      case 'admin':
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reporting'),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'Deals'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Coach'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
        ];
      case 'coach':
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'Deals'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Coach'),
        ];
      default:
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'Deals'),
        ];
    }
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _role = prefs.getString('role') ?? 'user';
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
