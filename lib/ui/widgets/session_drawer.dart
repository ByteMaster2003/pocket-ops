import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/ssh_session_state.dart';
import '../../services/session_manager.dart';

class SessionDrawer extends StatelessWidget {
  const SessionDrawer({super.key});

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.connected:
        return AppTheme.success;
      case SessionStatus.connecting:
        return AppTheme.primary;
      case SessionStatus.interrupted:
        return AppTheme.warning;
      case SessionStatus.error:
      case SessionStatus.disconnected:
        return AppTheme.error;
    }
  }

  String _getStatusLabel(SessionStatus status) {
    switch (status) {
      case SessionStatus.connected:
        return 'Active';
      case SessionStatus.connecting:
        return 'Connecting';
      case SessionStatus.interrupted:
        return 'Interrupted';
      case SessionStatus.error:
        return 'Failed';
      case SessionStatus.disconnected:
        return 'Closed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.surface,
      child: SafeArea(
        child: Consumer<SessionManager>(
          builder: (context, sessionMgr, _) {
            final sessions = sessionMgr.sessions;
            final activeSessionId = sessionMgr.activeSessionId;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.terminal, color: AppTheme.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Active Sessions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${sessions.length} live connection${sessions.length == 1 ? '' : 's'}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (sessions.isNotEmpty)
                        IconButton(
                          tooltip: 'Close All Sessions',
                          icon: const Icon(Icons.power_settings_new, color: AppTheme.error, size: 22),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppTheme.surface,
                                title: const Text('Close All Sessions?'),
                                content: const Text('This will terminate all active SSH connections.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      sessionMgr.closeAllSessions();
                                      Navigator.pop(context); // Close drawer
                                    },
                                    child: const Text('Disconnect All', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Sessions List
                Expanded(
                  child: sessions.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              'No live sessions.\nTap any server on the home screen to connect.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          itemCount: sessions.length,
                          separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final session = sessions[index];
                            final isActive = session.sessionId == activeSessionId;
                            final statusColor = _getStatusColor(session.status);

                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                sessionMgr.setActiveSession(session.sessionId);
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isActive ? AppTheme.cardColor : AppTheme.surfaceVariant.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isActive ? AppTheme.primary : AppTheme.border,
                                    width: isActive ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Status glowing dot
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: statusColor,
                                        boxShadow: [
                                          BoxShadow(
                                            color: statusColor.withValues(alpha: 0.5),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Server Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            session.server.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: isActive ? Colors.white : const Color(0xFFCBD5E1),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${session.server.username}@${session.server.host}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textMuted,
                                              fontFamily: 'monospace',
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Status Badge / Close Button
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _getStatusLabel(session.status),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18, color: AppTheme.textMuted),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        sessionMgr.closeSession(session.sessionId);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
