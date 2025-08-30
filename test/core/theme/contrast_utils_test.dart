import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/theme/contrast.dart';
import 'package:tapem/core/theme/design_tokens.dart';

void main() {
  test('mint/turquoise gradient picks black foreground', () {
    final grad = ensureGradientForeground(
      AppColors.accentMint,
      AppColors.accentTurquoise,
    );
    expect(grad.foreground, Colors.black);
  });
}
