import 'dart:async';
import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:xterm/xterm.dart';

import '../core/database/app_database.dart';
import '../core/security/secure_storage_service.dart';
import '../models/known_host.dart';
import '../models/server_profile.dart';
import '../models/ssh_session_state.dart';

typedef TofuPromptCallback = Future<bool> Function({
  required String host,
  required int port,
  required String keyType,
  required String fingerprint,
});

class SessionManager extends ChangeNotifier {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final List<LiveSSHSession> _sessions = [];
  String? _activeSessionId;

  List<LiveSSHSession> get sessions => List.unmodifiable(_sessions);
  String? get activeSessionId => _activeSessionId;

  LiveSSHSession? get activeSession {
    if (_activeSessionId == null) return null;
    return _sessions.cast<LiveSSHSession?>().firstWhere(
          (s) => s?.sessionId == _activeSessionId,
          orElse: () => null,
        );
  }

  void setActiveSession(String sessionId) {
    if (_activeSessionId != sessionId) {
      _activeSessionId = sessionId;
      notifyListeners();
    }
  }

  Future<LiveSSHSession> createAndConnectSession({
    required ServerProfile server,
    TofuPromptCallback? onTofuPrompt,
    String? fallbackPassword,
  }) async {
    // Check if session for this server is already open
    final existing = _sessions.cast<LiveSSHSession?>().firstWhere(
          (s) => s?.server.id == server.id && s?.status == SessionStatus.connected,
          orElse: () => null,
        );
    if (existing != null) {
      _activeSessionId = existing.sessionId;
      notifyListeners();
      return existing;
    }

    final sessionId = const Uuid().v4();
    final terminal = Terminal(maxLines: 5000);

    final session = LiveSSHSession(
      sessionId: sessionId,
      server: server,
      terminal: terminal,
      status: SessionStatus.connecting,
    );

    _sessions.add(session);
    _activeSessionId = sessionId;
    notifyListeners();

    terminal.write('\x1b[36m⚡ PocketOps SSH v1.0.0\x1b[0m\r\n');
    terminal.write('Connecting to ${server.username}@${server.host}:${server.port}...\r\n');

    _connect(session, onTofuPrompt: onTofuPrompt, fallbackPassword: fallbackPassword);

    return session;
  }

  Future<void> _connect(
    LiveSSHSession session, {
    TofuPromptCallback? onTofuPrompt,
    String? fallbackPassword,
  }) async {
    final server = session.server;
    final terminal = session.terminal;

    try {
      final socket = await SSHSocket.connect(
        server.host,
        server.port,
        timeout: const Duration(seconds: 10),
      );

      // Prepare authentication identities
      List<SSHKeyPair>? identities;
      if (server.keyAlias.isNotEmpty && server.keyAlias != 'password') {
        final pem = await SecureStorageService.instance.getPrivateKey(server.keyAlias);
        if (pem != null) {
          final passphrase = await SecureStorageService.instance.getKeyPassphrase(server.keyAlias);
          try {
            identities = SSHKeyPair.fromPem(pem, passphrase);
          } catch (e) {
            terminal.write('\x1b[31m[Auth Error] Failed to parse private key: $e\x1b[0m\r\n');
          }
        }
      }

      String? storedPassword = fallbackPassword;
      storedPassword ??= await SecureStorageService.instance.getServerPassword(server.id);

      final client = SSHClient(
        socket,
        username: server.username,
        identities: identities,
        keepAliveInterval: const Duration(seconds: 15),
        onVerifyHostKey: (type, fingerprintBytes) async {
          final fpStr = utf8.decode(fingerprintBytes);
          final knownHost = await AppDatabase.instance.getKnownHost(server.host, server.port);

          if (knownHost == null) {
            // TOFU verification prompt
            terminal.write('\r\n\x1b[33m[Host Verification] Unknown host key fingerprint: $fpStr\x1b[0m\r\n');
            if (onTofuPrompt != null) {
              final accepted = await onTofuPrompt(
                host: server.host,
                port: server.port,
                keyType: type,
                fingerprint: fpStr,
              );
              if (accepted) {
                await AppDatabase.instance.saveKnownHost(
                  KnownHost(
                    host: server.host,
                    port: server.port,
                    keyType: type,
                    fingerprint: fpStr,
                    firstSeenAt: DateTime.now().millisecondsSinceEpoch,
                  ),
                );
                return true;
              }
              return false;
            }
            // If no callback provided, accept & pin automatically
            await AppDatabase.instance.saveKnownHost(
              KnownHost(
                host: server.host,
                port: server.port,
                keyType: type,
                fingerprint: fpStr,
                firstSeenAt: DateTime.now().millisecondsSinceEpoch,
              ),
            );
            return true;
          }

          if (knownHost.fingerprint == fpStr) {
            return true;
          } else {
            terminal.write('\r\n\x1b[31;1m@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\r\n');
            terminal.write('@ WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED! @\r\n');
            terminal.write('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\r\n');
            terminal.write('Host fingerprint mismatch! Expected: ${knownHost.fingerprint}\r\n');
            terminal.write('Got: $fpStr\x1b[0m\r\n');
            return false;
          }
        },
        onPasswordRequest: () {
          return storedPassword;
        },
      );

      session.client = client;

      // Wait for authentication
      await client.authenticated;
      terminal.write('\x1b[32m✔ Authenticated successfully.\x1b[0m\r\n');

      // Update last connected time in SQLite
      await AppDatabase.instance.updateLastConnected(server.id);

      // Start shell session
      final channel = await client.shell(
        pty: SSHPtyConfig(
          width: terminal.viewWidth > 0 ? terminal.viewWidth : 80,
          height: terminal.viewHeight > 0 ? terminal.viewHeight : 24,
        ),
      );
      session.channel = channel;
      session.status = SessionStatus.connected;
      session.connectedAt = DateTime.now();
      notifyListeners();

      // Listen to channel outputs
      channel.stdout.listen(
        (data) => terminal.write(utf8.decode(data, allowMalformed: true)),
        onError: (e) {
          terminal.write('\r\n\x1b[31m[Stdout Error] $e\x1b[0m\r\n');
        },
      );

      channel.stderr.listen(
        (data) => terminal.write(utf8.decode(data, allowMalformed: true)),
        onError: (e) {
          terminal.write('\r\n\x1b[31m[Stderr Error] $e\x1b[0m\r\n');
        },
      );

      // Route terminal user input back to SSH channel
      terminal.onOutput = (input) {
        session.sendInput(input);
      };

      // Real-time PTY resize handler
      terminal.onResize = (width, height, pixelWidth, pixelHeight) {
        session.resize(width, height);
      };

      // Handle session close
      channel.done.then((_) {
        if (session.status != SessionStatus.disconnected) {
          session.status = SessionStatus.disconnected;
          terminal.write('\r\n\x1b[33mSession closed by remote host.\x1b[0m\r\n');
          notifyListeners();
        }
      });

      client.done.then((_) {
        if (session.status != SessionStatus.disconnected) {
          session.status = SessionStatus.disconnected;
          terminal.write('\r\n\x1b[33mConnection closed.\x1b[0m\r\n');
          notifyListeners();
        }
      });
    } catch (e) {
      session.status = SessionStatus.error;
      session.errorMessage = e.toString();
      terminal.write('\r\n\x1b[31mConnection failed: $e\x1b[0m\r\n');
      notifyListeners();
    }
  }

  Future<void> reconnectSession(LiveSSHSession session, {TofuPromptCallback? onTofuPrompt}) async {
    await session.dispose();
    session.status = SessionStatus.connecting;
    session.errorMessage = null;
    notifyListeners();

    session.terminal.write('\r\n\x1b[36mReconnecting...\x1b[0m\r\n');
    await _connect(session, onTofuPrompt: onTofuPrompt);
  }

  Future<void> closeSession(String sessionId) async {
    final index = _sessions.indexWhere((s) => s.sessionId == sessionId);
    if (index != -1) {
      final session = _sessions[index];
      await session.dispose();
      _sessions.removeAt(index);

      if (_activeSessionId == sessionId) {
        _activeSessionId = _sessions.isNotEmpty ? _sessions.last.sessionId : null;
      }
      notifyListeners();
    }
  }

  Future<void> closeAllSessions() async {
    for (final session in _sessions) {
      await session.dispose();
    }
    _sessions.clear();
    _activeSessionId = null;
    notifyListeners();
  }
}
