import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class MpinDots extends StatelessWidget {
  final int length;
  final int filledCount;
  final bool hasError;

  const MpinDots({
    super.key,
    this.length = 6,
    required this.filledCount,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final isFilled = index < filledCount;
        Color dotColor;
        if (hasError) {
          dotColor = AppTheme.error;
        } else if (isFilled) {
          dotColor = AppTheme.primary;
        } else {
          dotColor = AppTheme.borderLight;
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: isFilled ? 16 : 14,
          height: isFilled ? 16 : 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? dotColor : Colors.transparent,
            border: Border.all(
              color: dotColor,
              width: 2,
            ),
            boxShadow: isFilled && !hasError
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : hasError
                    ? [
                        BoxShadow(
                          color: AppTheme.error.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
          ),
        );
      }),
    );
  }
}
