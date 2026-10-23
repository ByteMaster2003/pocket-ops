import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TofuDialog extends StatelessWidget {
  final String host;
  final int port;
  final String keyType;
  final String fingerprint;

  const TofuDialog({
    super.key,
    required this.host,
    required this.port,
    required this.keyType,
    required this.fingerprint,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.borderLight, width: 1),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_outlined, color: AppTheme.warning, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Verify Host Key',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The authenticity of this remote host cannot be verified yet (Trust-On-First-Use). Do you want to trust this key and connect?',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Host', '$host:$port'),
          const SizedBox(height: 8),
          _buildInfoRow('Key Type', keyType.toUpperCase()),
          const SizedBox(height: 12),
          const Text(
            'Key Fingerprint (SHA-256):',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: SelectableText(
              fingerprint,
              style: AppTheme.terminalFont(
                fontSize: 12,
                color: AppTheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel / Reject', style: TextStyle(color: AppTheme.error)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: const Color(0xFF001E28),
          ),
          child: const Text('Trust & Connect'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ],
    );
  }
}
