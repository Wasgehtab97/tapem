import 'package:flutter/material.dart';

/// Keeps auth forms reachable while the software keyboard is visible.
class AuthKeyboardScrollView extends StatelessWidget {
  const AuthKeyboardScrollView({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.bottomSpacing = 20,
  });

  final Widget child;
  final EdgeInsets padding;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              padding.left,
              padding.top,
              padding.right,
              padding.bottom + keyboardInset + bottomSpacing,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
