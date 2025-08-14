import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/widgets/brand_gradient_card.dart';
import 'package:tapem/core/widgets/brand_primary_button.dart';

void main() {
  testWidgets('BrandGradientCard uses onBrand text colour', (tester) async {
    final theme = ThemeData(extensions: [AppBrandTheme.defaultTheme()]);
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: const BrandGradientCard(child: Text('card')),
    ));
    final text = tester.widget<Text>(find.text('card'));
    final brand = theme.extension<AppBrandTheme>()!;
    expect(text.style?.color, brand.onBrand);
  });

  testWidgets('BrandPrimaryButton exposes semantics and colours', (tester) async {
    final theme = ThemeData(extensions: [AppBrandTheme.defaultTheme()]);
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: BrandPrimaryButton(
        semanticsLabel: 'tap',
        onPressed: () {},
        child: const Text('tap'),
      ),
    ));
    final semantics = tester.getSemantics(find.byType(BrandPrimaryButton));
    expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
    final text = tester.widget<Text>(find.text('tap'));
    final brand = theme.extension<AppBrandTheme>()!;
    expect(text.style?.color, brand.onBrand);
  });
}
