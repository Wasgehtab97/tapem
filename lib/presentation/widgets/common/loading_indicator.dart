// lib/presentation/widgets/common/loading_indicator.dart

import 'package:flutter/material.dart';

/// Zeigt einen zentrierten Loading Spinner
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
