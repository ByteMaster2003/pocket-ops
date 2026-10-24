import 'package:flutter/material.dart';
import '../../core/security/app_lock_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/haptics.dart';
import '../widgets/mpin_dots.dart';
import '../widgets/numeric_keypad.dart';
import 'home_screen.dart';
import 'mpin_setup_screen.dart';

class MpinLockScreen extends StatefulWidget {
  const MpinLockScreen({super.key});

  @override
  State<MpinLockScreen> createState() => _MpinLockScreenState();
}

class _MpinLockScreenState extends State<MpinLockScreen> {
  String _enteredPin = '';
  bool _hasError = false;
  String _errorMessage = '';
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkAndPromptBiometric();
  }

  Future<void> _checkAndPromptBiometric() async {
    final enabled = await AppLockService.instance.isBiometricEnabled();
    final supported = await AppLockService.instance.isFingerprintAvailable();

    if (mounted) {
      setState(() {
        _biometricAvailable = enabled && supported;
      });
    }

    if (enabled && supported) {
      // Trigger prompt smoothly after frame renders
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _authenticateBiometric();
      });
    }
  }

  Future<void> _authenticateBiometric() async {
    final success = await AppLockService.instance.authenticateWithFingerprint();
    if (success && mounted) {
      Haptics.medium();
      _unlockApp();
    }
  }

  void _onDigit(String digit) {
    if (_enteredPin.length < 6) {
      setState(() {
        _hasError = false;
        _errorMessage = '';
        _enteredPin += digit;
      });

      if (_enteredPin.length == 6) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _hasError = false;
        _errorMessage = '';
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    final valid = await AppLockService.instance.verifyMpin(_enteredPin);
    if (valid) {
      Haptics.medium();
      _unlockApp();
    } else {
      Haptics.heavy();
      setState(() {
        _hasError = true;
        _errorMessage = 'Incorrect MPIN. Please try again.';
        _enteredPin = '';
      });
    }
  }

  void _unlockApp() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppTheme.borderLight),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Reset & Wipe Everything?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zero Cloud Telemetry & Hardware Keystore Guarantee:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'Because all your private keys and credentials are encrypted exclusively on this device with no cloud backup, forgetting your MPIN means all stored server profiles and private keys must be permanently deleted.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              'There is no second chance. You will have to set up PocketOps from scratch.',
              style: TextStyle(color: AppTheme.error, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await AppLockService.instance.wipeAllData();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MpinSetupScreen()),
                );
              }
            },
            child: const Text('Wipe & Reset App', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Logo & Title
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.terminal_rounded, size: 44, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pocket Ops',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Enter your 6-digit MPIN to unlock',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 32),

            // PIN Dots
            MpinDots(
              length: 6,
              filledCount: _enteredPin.length,
              hasError: _hasError,
            ),

            const SizedBox(height: 14),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: AppTheme.error, fontSize: 12, fontWeight: FontWeight.w600),
              )
            else
              const SizedBox(height: 16),

            const Spacer(),

            // Numeric Keypad
            NumericKeypad(
              onDigitPressed: _onDigit,
              onBackspacePressed: _onBackspace,
              showBiometric: _biometricAvailable,
              onBiometricPressed: _authenticateBiometric,
            ),

            const SizedBox(height: 16),

            // Forgot PIN button
            TextButton(
              onPressed: _showForgotPinDialog,
              child: const Text(
                'Forgot MPIN? Reset App',
                style: TextStyle(
                  color: AppTheme.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
