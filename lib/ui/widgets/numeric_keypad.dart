import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/haptics.dart';

class NumericKeypad extends StatelessWidget {
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback? onBiometricPressed;
  final bool showBiometric;

  const NumericKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onBackspacePressed,
    this.onBiometricPressed,
    this.showBiometric = false,
  });

  Widget _buildKeyButton({
    required Widget child,
    required VoidCallback onTap,
    bool isAction = false,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      width: 72,
      height: 72,
      child: Material(
        color: isAction ? Colors.transparent : AppTheme.surfaceVariant.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            Haptics.light();
            onTap();
          },
          splashColor: AppTheme.primary.withValues(alpha: 0.2),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildDigitButton(String digit) {
    return _buildKeyButton(
      child: Text(
        digit,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      onTap: () => onDigitPressed(digit),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDigitButton('1'),
            _buildDigitButton('2'),
            _buildDigitButton('3'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDigitButton('4'),
            _buildDigitButton('5'),
            _buildDigitButton('6'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDigitButton('7'),
            _buildDigitButton('8'),
            _buildDigitButton('9'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showBiometric && onBiometricPressed != null)
              _buildKeyButton(
                isAction: true,
                child: const Icon(Icons.fingerprint_rounded, size: 32, color: AppTheme.primary),
                onTap: onBiometricPressed!,
              )
            else
              const SizedBox(width: 72, height: 72),
            _buildDigitButton('0'),
            _buildKeyButton(
              isAction: true,
              child: const Icon(Icons.backspace_outlined, size: 24, color: AppTheme.textMuted),
              onTap: onBackspacePressed,
            ),
          ],
        ),
      ],
    );
  }
}
