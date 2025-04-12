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
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String? userRole;
  bool _roleLoaded = false;

  // Standardseiten für Nutzer mit der Rolle "user"
  final List<Widget> _userPages = [
    const ProfileScreen(),
    const AffiliateScreen(),
  ];

  // Extra-Seiten für Admins
  final List<Widget> _adminPages = [
    const ProfileScreen(),
    const ReportDashboardScreen(),
    const AffiliateScreen(),
    AdminDashboardScreen(),
  ];

  // Extra-Seiten für Coaches
  final List<Widget> _coachPages = [
    const ProfileScreen(),
    const AffiliateScreen(),
    const CoachDashboardScreen(),
  ];

  List<Widget> get _pages {
    if (userRole == 'admin') {
      return _adminPages;
    } else if (userRole == 'coach') {
      return _coachPages;
    } else if (userRole == 'user') {
      return _userPages;
    }
    // Falls keine Rolle gesetzt ist, wird standardmäßig die Nutzer-Variante genutzt
    return _userPages;
  }

  List<BottomNavigationBarItem> get _navigationItems {
    if (userRole == 'admin') {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Reporting',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_offer),
          label: 'Deals',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      ];
    } else if (userRole == 'coach') {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_offer),
          label: 'Deals',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.supervisor_account),
          label: 'Coach',
        ),
      ];
    } else if (userRole == 'user') {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_offer),
          label: 'Deals',
        ),
      ];
    }
    // Standardmäßig für den Fall, dass keine Rolle gesetzt ist:
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profil',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.local_offer),
        label: 'Deals',
      ),
    ];
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('role');
    debugPrint('Geladene Rolle: $role');
    setState(() {
      userRole = role;
      _roleLoaded = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_roleLoaded) {
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
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: _navigationItems,
      ),
    );
  }
}
