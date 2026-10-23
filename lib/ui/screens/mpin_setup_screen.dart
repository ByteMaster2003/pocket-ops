import 'package:flutter/material.dart';
import '../../core/security/app_lock_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/haptics.dart';
import '../widgets/mpin_dots.dart';
import '../widgets/numeric_keypad.dart';
import 'home_screen.dart';

class MpinSetupScreen extends StatefulWidget {
  final bool isResetting;

  const MpinSetupScreen({super.key, this.isResetting = false});

  @override
  State<MpinSetupScreen> createState() => _MpinSetupScreenState();
}

class _MpinSetupScreenState extends State<MpinSetupScreen> {
  String _firstPin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _hasError = false;
  String _errorMessage = '';

  bool _fingerprintSupported = false;
  bool _enableFingerprint = true;

  @override
  void initState() {
    super.initState();
    _checkFingerprintSupport();
  }

  Future<void> _checkFingerprintSupport() async {
    final supported = await AppLockService.instance.isFingerprintAvailable();
    if (mounted) {
      setState(() {
        _fingerprintSupported = supported;
      });
    }
  }

  void _onDigit(String digit) {
    if (_hasError) {
      setState(() {
        _hasError = false;
        _errorMessage = '';
      });
    }

    if (!_isConfirming) {
      if (_firstPin.length < 6) {
        setState(() {
          _firstPin += digit;
        });
        if (_firstPin.length == 6) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              setState(() {
                _isConfirming = true;
              });
            }
          });
        }
      }
    } else {
      if (_confirmPin.length < 6) {
        setState(() {
          _confirmPin += digit;
        });
        if (_confirmPin.length == 6) {
          _verifyAndSave();
        }
      }
    }
  }

  void _onBackspace() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      if (_isConfirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          // Go back to first PIN
          _isConfirming = false;
          _firstPin = '';
        }
      } else {
        if (_firstPin.isNotEmpty) {
          _firstPin = _firstPin.substring(0, _firstPin.length - 1);
        }
      }
    });
  }

  Future<void> _verifyAndSave() async {
    if (_firstPin != _confirmPin) {
      Haptics.heavy();
      setState(() {
        _hasError = true;
        _errorMessage = 'MPINs do not match. Please try again.';
        _confirmPin = '';
      });
      return;
    }

    Haptics.medium();
    await AppLockService.instance.setMpin(_firstPin);
    if (_fingerprintSupported && _enableFingerprint) {
      await AppLockService.instance.setBiometricEnabled(true);
    } else {
      await AppLockService.instance.setBiometricEnabled(false);
    }

    if (mounted) {
      if (widget.isResetting) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeLength = _isConfirming ? _confirmPin.length : _firstPin.length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: widget.isResetting
          ? AppBar(
              title: const Text('Reset MPIN'),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Lock icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_rounded, size: 40, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isConfirming ? 'Confirm Your MPIN' : 'Set Up Security MPIN',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isConfirming
                          ? 'Re-enter your 6-digit MPIN to verify'
                          : 'Create a 6-digit MPIN. This is mandatory to secure your local SSH keys.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
                    ),
                    const SizedBox(height: 28),

                    // Animated Dots
                    MpinDots(
                      length: 6,
                      filledCount: activeLength,
                      hasError: _hasError,
                    ),

                    const SizedBox(height: 12),
                    if (_errorMessage.isNotEmpty)
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: AppTheme.error, fontSize: 12, fontWeight: FontWeight.w600),
                      )
                    else
                      const SizedBox(height: 16),

                    const SizedBox(height: 12),

                    // Local-only security warning banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Hardware Keystore Protection: Stored 100% locally with zero cloud backup. If you forget your MPIN, all keys and servers must be wiped and setup again.',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_fingerprintSupported && !_isConfirming) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.fingerprint_rounded, color: AppTheme.primary, size: 24),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fingerprint Unlock',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                                  ),
                                  Text(
                                    'Biometric fast unlock',
                                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _enableFingerprint,
                              activeThumbColor: AppTheme.primary,
                              onChanged: (val) {
                                setState(() {
                                  _enableFingerprint = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Keypad
            NumericKeypad(
              onDigitPressed: _onDigit,
              onBackspacePressed: _onBackspace,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
