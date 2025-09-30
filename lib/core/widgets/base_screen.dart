import 'package:flutter/material.dart';
import 'package:tapem/core/widgets/global_app_bar_actions.dart';

/// BaseScreen: Gemeinsamer Scaffold mit AppBar-Titel und NFC-Scan-Button.
/// Alle Screens, die diese Basisklasse nutzen, erhalten automatisch den NFC-Button.
class BaseScreen extends StatelessWidget {
  final String title;
  final Widget child;

  const BaseScreen({required this.title, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: buildGlobalAppBarActions(),
      ),
      body: child,
    );
  }
}
