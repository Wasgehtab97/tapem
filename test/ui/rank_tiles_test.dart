import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/brand_on_colors.dart';
import 'package:tapem/core/widgets/brand_action_tile.dart';

void main() {
  testWidgets('Rank tile text and chevron use onGradient colour', (tester) async {
    const onGrad = Colors.black;
    final theme = ThemeData(extensions: [
      AppBrandTheme.defaultTheme(),
      const BrandOnColors(
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onGradient: onGrad,
        onCta: Colors.black,
      ),
    ]);

    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: const BrandActionTile(title: 'tile'),
    ));

    final text = tester.widget<Text>(find.text('tile'));
    expect(text.style?.color, onGrad);

    final icon = tester.widget<Icon>(find.byIcon(Icons.chevron_right));
    expect(icon.color, onGrad);
  });
}
