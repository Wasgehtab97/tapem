import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/theme/theme.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/auth/presentation/widgets/login_form.dart';
import 'package:tapem/features/auth/presentation/widgets/registration_form.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final loc = AppLocalizations.of(context)!;

    return Theme(
      data: AppTheme.neutralTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.authTitle),
          bottom: TabBar(
            controller: _tabController,
            tabs: [Tab(text: loc.loginButton), Tab(text: loc.registerButton)],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              controller: _tabController,
              children: const [LoginForm(), RegistrationForm()],
            ),
            if (authProv.isLoading)
              Container(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
