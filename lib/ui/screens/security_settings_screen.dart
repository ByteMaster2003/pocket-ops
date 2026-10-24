import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/security/app_lock_service.dart';
import '../../core/theme/app_theme.dart';
import 'mpin_setup_screen.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _biometricEnabled = false;
  bool _biometricSupported = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await AppLockService.instance.isBiometricEnabled();
    final supported = await AppLockService.instance.isFingerprintAvailable();

    if (mounted) {
      setState(() {
        _biometricEnabled = enabled;
        _biometricSupported = supported;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometrics(bool val) async {
    await AppLockService.instance.setBiometricEnabled(val);
    setState(() {
      _biometricEnabled = val;
    });
  }

  void _showChangeMpinDialog() {
    final oldPinController = TextEditingController();
    bool isVerifying = false;
    String? errorText;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Verify Current MPIN'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your current 6-digit MPIN before setting a new one.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: oldPinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Current MPIN',
                    errorText: errorText,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isVerifying
                    ? null
                    : () async {
                        final pin = oldPinController.text.trim();
                        if (pin.length != 6) {
                          setDlgState(() => errorText = 'Enter 6 digits');
                          return;
                        }

                        setDlgState(() => isVerifying = true);
                        final valid = await AppLockService.instance.verifyMpin(pin);
                        if (!valid) {
                          setDlgState(() {
                            isVerifying = false;
                            errorText = 'Incorrect MPIN';
                          });
                          return;
                        }

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }

                        if (mounted) {
                          final updated = await navigator.push<bool>(
                            MaterialPageRoute(
                              builder: (_) => const MpinSetupScreen(isResetting: true),
                            ),
                          );

                          if (updated == true && mounted) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('MPIN updated successfully.'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          }
                        }
                      },
                child: const Text('Verify & Proceed'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showWipeDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.error),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppTheme.error, size: 28),
            SizedBox(width: 10),
            Text('Erase All Data?'),
          ],
        ),
        content: const Text(
          'This will permanently delete all saved server profiles, known hosts, and hardware keystore private keys. You will need to setup your MPIN again.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await AppLockService.instance.wipeAllData();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MpinSetupScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Erase Everything', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Security & Access'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Section: Authentication
                const Text(
                  'AUTHENTICATION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 12),

                // Change MPIN card
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.pin_rounded, color: AppTheme.primary, size: 22),
                    ),
                    title: const Text('Change MPIN', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    subtitle: const Text('Update your 6-digit app passcode', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                    onTap: _showChangeMpinDialog,
                  ),
                ),

                const SizedBox(height: 12),

                // Biometrics toggle card
                if (_biometricSupported)
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      secondary: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.fingerprint_rounded, color: AppTheme.primary, size: 22),
                      ),
                      title: const Text('Fingerprint Unlock', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                      subtitle: const Text('Unlock PocketOps with your biometric fingerprint', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      value: _biometricEnabled,
                      activeThumbColor: AppTheme.primary,
                      onChanged: _toggleBiometrics,
                    ),
                  ),

                const SizedBox(height: 32),

                // Section: Local Privacy & Storage
                const Text(
                  'PRIVACY & LOCAL STORAGE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lock_outline, color: AppTheme.success, size: 20),
                          SizedBox(width: 8),
                          Text('100% Local Device Storage', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        'All SSH private keys are isolated inside the Android Hardware Keystore. There is no telemetry, analytics, or remote synchronization.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Section: About & Privacy
                const Text(
                  'DEVELOPER & PRIVACY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.privacy_tip_outlined, color: AppTheme.primary, size: 20),
                        ),
                        title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14)),
                        subtitle: const Text('pocket-ops privacy practices', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        trailing: const Icon(Icons.open_in_new, size: 18, color: AppTheme.textMuted),
                        onTap: () async {
                          final uri = Uri.parse('https://viveksahani.com/apps/pocket-ops/privacy-policy');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.language_rounded, color: AppTheme.primary, size: 20),
                        ),
                        title: const Text('Developer Website', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14)),
                        subtitle: const Text('https://viveksahani.com', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        trailing: const Icon(Icons.open_in_new, size: 18, color: AppTheme.textMuted),
                        onTap: () async {
                          final uri = Uri.parse('https://viveksahani.com');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Danger zone
                const Text(
                  'DANGER ZONE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: AppTheme.error,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_forever_rounded, color: AppTheme.error, size: 22),
                    ),
                    title: const Text('Erase All Data & Reset', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.error)),
                    subtitle: const Text('Wipe all servers, keys, and reset MPIN', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.error),
                    onTap: _showWipeDataDialog,
                  ),
                ),
              ],
            ),
    );
  }
}
