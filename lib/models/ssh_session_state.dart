import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';
import 'server_profile.dart';

enum SessionStatus {
  connecting,
  connected,
  disconnected,
  interrupted,
  error,
}

class LiveSSHSession {
  final String sessionId;
  final ServerProfile server;
  final Terminal terminal;
  SSHClient? client;
  SSHSession? channel;
  SessionStatus status;
  String? errorMessage;
  DateTime? connectedAt;
  Timer? keepAliveTimer;

  LiveSSHSession({
    required this.sessionId,
    required this.server,
    required this.terminal,
    this.status = SessionStatus.connecting,
    this.errorMessage,
  });

  void sendInput(String input) {
    if (channel != null && status == SessionStatus.connected) {
      channel?.write(Uint8List.fromList(utf8.encode(input)));
    }
  }

  void resize(int width, int height) {
    if (channel != null && status == SessionStatus.connected) {
      try {
        channel?.resizeTerminal(width, height);
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    keepAliveTimer?.cancel();
    keepAliveTimer = null;
    try {
      channel?.close();
    } catch (_) {}
    try {
      client?.close();
    } catch (_) {}
    status = SessionStatus.disconnected;
  }
}
