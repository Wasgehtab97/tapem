import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/brand_on_colors.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/theme/contrast.dart';
import 'package:tapem/core/widgets/brand_gradient_card.dart';
import 'package:tapem/core/widgets/brand_primary_button.dart';
import 'package:tapem/core/widgets/brand_outline.dart';

void main() {
  testWidgets('BrandGradientCard uses onBrand text colour', (tester) async {
    final theme = ThemeData(extensions: [
      AppBrandTheme.defaultTheme(),
      const BrandOnColors(
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onGradient: Colors.white,
        onCta: Colors.white,
      ),
    ]);
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: const BrandGradientCard(child: Text('card')),
    ));
    final text = tester.widget<Text>(find.text('card'));
    final brand = theme.extension<BrandOnColors>()!;
    expect(text.style?.color, brand.onGradient);
  });

  testWidgets('BrandPrimaryButton exposes semantics and colours', (tester) async {
    final theme = ThemeData(extensions: [
      AppBrandTheme.defaultTheme(),
      const BrandOnColors(
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onGradient: Colors.white,
        onCta: Colors.white,
      ),
    ]);
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
    final brand = theme.extension<BrandOnColors>()!;
    expect(text.style?.color, brand.onCta);
    final grad = AppGradients.brandGradient;
    final ratios = [
      contrastRatio(grad.colors.first, brand.onCta),
      contrastRatio(grad.colors.last, brand.onCta),
      contrastRatio(Color.lerp(grad.colors.first, grad.colors.last, 0.5)!,
          brand.onCta),
    ];
    expect(ratios.every((r) => r >= 4.5), isTrue);
  });

  testWidgets('BrandOutline uses gradient from theme and handles states',
      (tester) async {
    final theme = ThemeData(extensions: [
      AppBrandTheme.defaultTheme(),
      const BrandOnColors(
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onGradient: Colors.white,
        onCta: Colors.white,
      ),
    ]);
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: Center(
        child: BrandOutline(
          onTap: () {},
          semanticLabel: 'outline',
          child: const Text('outlined'),
        ),
      ),
    ));
    final brand = theme.extension<AppBrandTheme>()!;
    final ink = tester.widget<InkWell>(find.byType(InkWell));
    expect(
      ink.overlayColor!.resolve({MaterialState.pressed}),
      brand.pressedOverlay,
    );
    final semantics = tester.getSemantics(find.byType(BrandOutline));
    expect(semantics.label, 'outline');
  });

  testWidgets('BrandOutline applies disabled opacity', (tester) async {
    final theme = ThemeData(extensions: [AppBrandTheme.defaultTheme()]);
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: BrandOutline(
        isDisabled: true,
        child: const Text('disabled'),
      ),
    ));
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: find.text('disabled'), matching: find.byType(Opacity)),
    );
    final brand = theme.extension<AppBrandTheme>()!;
    expect(opacity.opacity, brand.outlineDisabledOpacity);
  });
}
