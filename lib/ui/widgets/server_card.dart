import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/server_profile.dart';

class ServerCard extends StatelessWidget {
  final ServerProfile server;
  final bool isSessionActive;
  final VoidCallback onConnect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ServerCard({
    super.key,
    required this.server,
    this.isSessionActive = false,
    required this.onConnect,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatLastConnected(int? timestamp) {
    if (timestamp == null) return 'Never connected';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = server.keyAlias.isNotEmpty && server.keyAlias != 'password';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSessionActive ? AppTheme.primary : AppTheme.border,
          width: isSessionActive ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onConnect,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Server Icon & Name
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSessionActive
                                  ? AppTheme.primary.withValues(alpha: 0.15)
                                  : AppTheme.surfaceVariant.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.dns_rounded,
                              color: isSessionActive ? AppTheme.primary : const Color(0xFF94A3B8),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        server.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isSessionActive) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.success.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.circle, color: AppTheme.success, size: 6),
                                            SizedBox(width: 4),
                                            Text(
                                              'LIVE',
                                              style: TextStyle(
                                                color: AppTheme.success,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${server.username}@${server.host}:${server.port}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                    color: AppTheme.textMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Actions popup
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppTheme.textMuted, size: 20),
                      color: AppTheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppTheme.border),
                      ),
                      onSelected: (val) {
                        if (val == 'edit') onEdit();
                        if (val == 'delete') onDelete();
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18, color: Colors.white),
                              SizedBox(width: 10),
                              Text('Edit Profile'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                              SizedBox(width: 10),
                              Text('Delete', style: TextStyle(color: AppTheme.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Footer Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Auth type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasKey ? Icons.key_rounded : Icons.password_rounded,
                            size: 13,
                            color: hasKey ? AppTheme.primary : AppTheme.warning,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            hasKey ? 'Key: ${server.keyAlias}' : 'Password Auth',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: hasKey ? AppTheme.primary : AppTheme.warning,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Last connected
                    Row(
                      children: [
                        const Icon(Icons.history_rounded, size: 13, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          _formatLastConnected(server.lastConnectedAt),
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
