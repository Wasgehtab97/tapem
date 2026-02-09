import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/auth_theme.dart';

class AnimatedTabIndicator extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;

  const AnimatedTabIndicator({
    Key? key,
    required this.controller,
    required this.tabs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          height: 48,
          decoration: BoxDecoration(
            color: AuthTheme.surfaceRaised,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AuthTheme.border),
          ),
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final tabWidth = constraints.maxWidth / tabs.length;
                  return AnimatedAlign(
                    duration: AuthTheme.animationDurationFast,
                    curve: Curves.easeOutCubic,
                    alignment: Alignment(
                      (controller.index * 2 / (tabs.length - 1)) - 1,
                      0,
                    ),
                    child: Container(
                      width: tabWidth - 4,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              Row(
                children: tabs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final text = entry.value;
                  final isSelected = controller.index == index;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        controller.animateTo(index);
                      },
                      behavior: HitTestBehavior
                          .translucent, // Ensure tap target fills area
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: AuthTheme.animationDurationFast,
                          style: AuthTheme.buttonTextStyle.copyWith(
                            color: isSelected
                                ? Colors.black
                                : AuthTheme.textMuted,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          child: Text(text),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
