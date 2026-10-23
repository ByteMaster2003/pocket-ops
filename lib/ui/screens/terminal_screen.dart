import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/haptics.dart';
import '../../models/ssh_session_state.dart';
import '../../services/session_manager.dart';
import '../widgets/accessory_keyboard_bar.dart';
import '../widgets/session_drawer.dart';
import '../widgets/tofu_dialog.dart';

class TerminalScreen extends StatefulWidget {
  final String sessionId;

  const TerminalScreen({super.key, required this.sessionId});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TerminalController _terminalController = TerminalController();

  Future<bool> _showTofuPrompt({
    required String host,
    required int port,
    required String keyType,
    required String fingerprint,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => TofuDialog(
        host: host,
        port: port,
        keyType: keyType,
        fingerprint: fingerprint,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionManager>(
      builder: (context, sessionMgr, _) {
        final session = sessionMgr.activeSession;

        if (session == null) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(
              title: const Text('Terminal'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.terminal_outlined, size: 64, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  const Text('No active session.', style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Servers'),
                  ),
                ],
              ),
            ),
          );
        }

        final statusColor = session.status == SessionStatus.connected
            ? AppTheme.success
            : session.status == SessionStatus.connecting
                ? AppTheme.primary
                : AppTheme.error;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.black,
          endDrawer: const SessionDrawer(),
          appBar: AppBar(
            backgroundColor: AppTheme.surface,
            elevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to servers (Session stays alive)',
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.6),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        session.server.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${session.server.username}@${session.server.host}:${session.server.port}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            actions: [
              // Reconnect button if disconnected or error
              if (session.status != SessionStatus.connected)
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppTheme.primary),
                  tooltip: 'Reconnect',
                  onPressed: () {
                    Haptics.medium();
                    sessionMgr.reconnectSession(
                      session,
                      onTofuPrompt: _showTofuPrompt,
                    );
                  },
                ),

              // Drawer toggle (shows active session count badge)
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.view_sidebar_outlined),
                    tooltip: 'Sessions Switcher',
                    onPressed: () {
                      _scaffoldKey.currentState?.openEndDrawer();
                    },
                  ),
                  if (sessionMgr.sessions.length > 1)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${sessionMgr.sessions.length}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF001E28),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Disconnect button
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.error),
                tooltip: 'Disconnect session',
                onPressed: () {
                  sessionMgr.closeSession(session.sessionId);
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Terminal viewport
                Expanded(
                  child: Container(
                    color: const Color(0xFF070B12),
                    child: TerminalView(
                      session.terminal,
                      controller: _terminalController,
                      theme: TerminalThemes.defaultTheme,
                      textStyle: const TerminalStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                      autofocus: true,
                    ),
                  ),
                ),

                // Accessory keyboard row
                AccessoryKeyboardBar(session: session),
              ],
            ),
          ),
        );
      },
    );
  }
}
