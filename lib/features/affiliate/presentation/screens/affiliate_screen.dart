// lib/features/affiliate/presentation/screens/affiliate_screen.dart
import 'package:flutter/material.dart';

class AffiliateScreen extends StatelessWidget {
  const AffiliateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Affiliate')),
      body: const Center(child: Text('Affiliate-Bereich hier')),
    );
  }
}
