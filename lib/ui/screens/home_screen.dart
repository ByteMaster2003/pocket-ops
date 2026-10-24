import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/database/app_database.dart';
import '../../core/security/secure_storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/haptics.dart';
import '../../models/server_profile.dart';
import '../../models/ssh_session_state.dart';
import '../../services/session_manager.dart';
import '../widgets/server_card.dart';
import '../widgets/session_drawer.dart';
import '../widgets/tofu_dialog.dart';
import 'key_manager_screen.dart';
import 'security_settings_screen.dart';
import 'server_form_screen.dart';
import 'terminal_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  List<ServerProfile> _servers = [];
  List<ServerProfile> _recentServers = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final servers = await AppDatabase.instance.getAllServers();
    final recents = await AppDatabase.instance.getRecentServers(limit: 5);

    setState(() {
      _servers = servers;
      _recentServers = recents;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _connectToServer(ServerProfile server) async {
    Haptics.medium();
    final sessionMgr = Provider.of<SessionManager>(context, listen: false);

    // If password auth is used and not saved, ask user
    String? fallbackPassword;
    if (server.keyAlias.isEmpty || server.keyAlias == 'password') {
      final savedPwd = await SecureStorageService.instance.getServerPassword(server.id);
      if (savedPwd == null && mounted) {
        fallbackPassword = await _promptPassword(server);
        if (fallbackPassword == null) return; // User cancelled
      }
    }

    if (!mounted) return;

    // Start session
    final session = await sessionMgr.createAndConnectSession(
      server: server,
      fallbackPassword: fallbackPassword,
      onTofuPrompt: ({
        required String host,
        required int port,
        required String keyType,
        required String fingerprint,
      }) async {
        final accepted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => TofuDialog(
            host: host,
            port: port,
            keyType: keyType,
            fingerprint: fingerprint,
          ),
        );
        return accepted ?? false;
      },
    );

    _loadData();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TerminalScreen(sessionId: session.sessionId),
        ),
      ).then((_) => _loadData());
    }
  }

  Future<String?> _promptPassword(ServerProfile server) async {
    final pwdController = TextEditingController();
    bool savePassword = true;

    return await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Password for ${server.username}@${server.host}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pwdController,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'SSH Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: savePassword,
                title: const Text('Save to Hardware Keystore', style: TextStyle(fontSize: 13)),
                onChanged: (val) {
                  setDlgState(() => savePassword = val ?? false);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final pwd = pwdController.text;
                if (savePassword) {
                  await SecureStorageService.instance.saveServerPassword(server.id, pwd);
                }
                if (ctx.mounted) {
                  Navigator.pop(ctx, pwd);
                }
              },
              child: const Text('Connect'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteServer(ServerProfile server) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Server Profile?'),
        content: Text('Remove "${server.name}" (${server.host})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AppDatabase.instance.deleteServer(server.id);
      await SecureStorageService.instance.deleteServerPassword(server.id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionMgr = context.watch<SessionManager>();
    final activeSessions = sessionMgr.sessions;

    final filteredServers = _servers.where((s) {
      final q = _searchQuery.toLowerCase();
      return s.name.toLowerCase().contains(q) || s.host.toLowerCase().contains(q) || s.username.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.background,
      endDrawer: const SessionDrawer(),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.terminal, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Pocket Ops'),
          ],
        ),
        actions: [
          // Manage Keys button
          IconButton(
            tooltip: 'SSH Keys',
            icon: const Icon(Icons.vpn_key_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KeyManagerScreen()),
              );
            },
          ),

          // Security Settings button
          IconButton(
            tooltip: 'Security & PIN',
            icon: const Icon(Icons.shield_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()),
              );
            },
          ),

          // Active sessions indicator / drawer trigger
          if (activeSessions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.success,
                  ),
                ),
                label: Text(
                  '${activeSessions.length} Live',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                onPressed: () {
                  _scaffoldKey.currentState?.openEndDrawer();
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: const Color(0xFF001E28),
        icon: const Icon(Icons.add),
        label: const Text('Add Server', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const ServerFormScreen()),
          );
          if (added == true) {
            _loadData();
          }
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              color: AppTheme.primary,
              backgroundColor: AppTheme.surface,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by label, host or user...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: AppTheme.textMuted, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                      ),
                    ),

                    // Recent servers section (if any)
                    if (_recentServers.isNotEmpty && _searchQuery.isEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'RECENT SERVERS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          Text(
                            '${_recentServers.length} recent',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 52,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _recentServers.length,
                          separatorBuilder: (c, i) => const SizedBox(width: 8),
                          itemBuilder: (ctx, i) {
                            final s = _recentServers[i];
                            final isLive = activeSessions.any((as) => as.server.id == s.id && as.status == SessionStatus.connected);

                            return ActionChip(
                              backgroundColor: isLive ? AppTheme.cardColor : AppTheme.surfaceVariant.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isLive ? AppTheme.primary : AppTheme.border,
                                ),
                              ),
                              avatar: Icon(
                                Icons.bolt_rounded,
                                size: 16,
                                color: isLive ? AppTheme.primary : AppTheme.textMuted,
                              ),
                              label: Text(
                                s.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isLive ? AppTheme.primary : Colors.white,
                                ),
                              ),
                              onPressed: () => _connectToServer(s),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Servers header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SAVED HOSTS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        Text(
                          '${filteredServers.length} host${filteredServers.length == 1 ? '' : 's'}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Server profiles list
                    if (filteredServers.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty ? 'No Server Profiles Added' : 'No matching servers',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Add your Linux / Cloud / VPS server to begin.'
                                    : 'Try a different search keyword.',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                              ),
                              if (_searchQuery.isEmpty) ...[
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final added = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(builder: (_) => const ServerFormScreen()),
                                    );
                                    if (added == true) _loadData();
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Server Profile'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredServers.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final server = filteredServers[index];
                          final isSessionActive = activeSessions.any(
                            (s) => s.server.id == server.id && s.status == SessionStatus.connected,
                          );

                          return ServerCard(
                            server: server,
                            isSessionActive: isSessionActive,
                            onConnect: () => _connectToServer(server),
                            onEdit: () async {
                              final updated = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ServerFormScreen(serverToEdit: server),
                                ),
                              );
                              if (updated == true) _loadData();
                            },
                            onDelete: () => _deleteServer(server),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
