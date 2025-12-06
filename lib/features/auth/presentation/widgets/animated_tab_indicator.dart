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
          height: 50,
          decoration: BoxDecoration(
            color: AuthTheme.glassColor,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AuthTheme.glassBorderColor),
          ),
          child: Stack(
            children: [
              // Sliding Indicator
              LayoutBuilder(
                builder: (context, constraints) {
                  final tabWidth = constraints.maxWidth / tabs.length;
                  return AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment(
                      (controller.index * 2 / (tabs.length - 1)) - 1,
                      0,
                    ),
                    child: Container(
                      width: tabWidth,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: AuthTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Tab Labels
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
                      behavior: HitTestBehavior.translucent, // Ensure tap target fills area
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: AuthTheme.buttonTextStyle.copyWith(
                            color: Colors.white.withOpacity(isSelected ? 1 : 0.6),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
