import 'package:flutter/material.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';

/// A vertical alphabet scrollbar for quick navigation through a list.
/// 
/// Displays letters A-Z on the right side of the screen.
/// When a letter is tapped or dragged, calls [onLetterSelected] with that letter.
class AlphabetScrollbar extends StatefulWidget {
  const AlphabetScrollbar({
    super.key,
    required this.onLetterSelected,
    this.currentLetter,
  });

  final ValueChanged<String> onLetterSelected;
  final String? currentLetter;

  @override
  State<AlphabetScrollbar> createState() => _AlphabetScrollbarState();
}

class _AlphabetScrollbarState extends State<AlphabetScrollbar> {
  static const _letters = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  ];

  String? _activeLetter;

  void _handleLetterTap(String letter) {
    setState(() => _activeLetter = letter);
    widget.onLetterSelected(letter);
    
    // Reset active letter after animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _activeLetter = null);
      }
    });
  }

  void _handleDragUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    final innerHeight = constraints.maxHeight - 2.0; // Account for 1px border top/bottom
    final itemHeight = innerHeight / _letters.length;
    final index = (localPosition.dy / itemHeight).floor().clamp(0, _letters.length - 1);
    
    final letter = _letters[index];
    if (letter != _activeLetter) {
      setState(() => _activeLetter = letter);
      widget.onLetterSelected(letter);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Ensure we have enough height to display letters comfortably
        // 26 letters * ~10px min height = ~260px.
        if (constraints.maxHeight < 300.0) {
          return const SizedBox();
        }

        return GestureDetector(
          onVerticalDragStart: (_) {},
          onVerticalDragUpdate: (details) => _handleDragUpdate(details, constraints),
          onVerticalDragEnd: (_) {
            setState(() => _activeLetter = null);
          },
          child: Container(
            width: 24,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.onSurface.withOpacity(0.1),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _letters.map((letter) {
                final isActive = letter == _activeLetter || letter == widget.currentLetter;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _handleLetterTap(letter),
                    child: Container(
                      width: 24,
                      alignment: Alignment.center,
                      color: Colors.transparent, // Hit test target
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 150),
                        style: TextStyle(
                          fontSize: isActive ? 13 : 10,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          color: isActive 
                              ? brandColor 
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        child: Text(letter),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
