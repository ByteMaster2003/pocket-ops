import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/haptics.dart';
import '../../models/ssh_session_state.dart';

class AccessoryKeyboardBar extends StatefulWidget {
  final LiveSSHSession session;

  const AccessoryKeyboardBar({
    super.key,
    required this.session,
  });

  @override
  State<AccessoryKeyboardBar> createState() => _AccessoryKeyboardBarState();
}

class _AccessoryKeyboardBarState extends State<AccessoryKeyboardBar> {
  bool _ctrlActive = false;
  bool _altActive = false;

  void _sendKey(String sequence) {
    Haptics.light();
    if (_ctrlActive && sequence.length == 1) {
      final code = sequence.toUpperCase().codeUnitAt(0) - 64;
      if (code > 0 && code <= 26) {
        widget.session.terminal.textInput(String.fromCharCode(code));
        setState(() {
          _ctrlActive = false;
        });
        return;
      }
    }
    if (_altActive && sequence.length == 1) {
      widget.session.terminal.textInput('\x1b$sequence');
      setState(() {
        _altActive = false;
      });
      return;
    }
    widget.session.terminal.textInput(sequence);
  }

  Widget _buildKeyButton({
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool isAccent = false,
    double minWidth = 44,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      constraints: BoxConstraints(minWidth: minWidth, minHeight: 38),
      child: Material(
        color: isActive
            ? AppTheme.primary
            : isAccent
                ? AppTheme.surfaceVariant
                : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(8),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          splashColor: AppTheme.primary.withValues(alpha: 0.3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? AppTheme.primary
                    : isAccent
                        ? AppTheme.borderLight
                        : AppTheme.border,
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive ? const Color(0xFF001E28) : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.border, width: 1),
          bottom: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            // Modifier: CTRL
            _buildKeyButton(
              label: 'CTRL',
              isActive: _ctrlActive,
              isAccent: true,
              onTap: () {
                Haptics.selection();
                setState(() {
                  _ctrlActive = !_ctrlActive;
                });
              },
            ),

            // Modifier: ALT
            _buildKeyButton(
              label: 'ALT',
              isActive: _altActive,
              isAccent: true,
              onTap: () {
                Haptics.selection();
                setState(() {
                  _altActive = !_altActive;
                });
              },
            ),

            // ESC
            _buildKeyButton(
              label: 'ESC',
              onTap: () => _sendKey('\x1b'),
            ),

            // TAB
            _buildKeyButton(
              label: 'TAB',
              onTap: () => _sendKey('\t'),
            ),

            // Quick Ctrl combos
            _buildKeyButton(
              label: '^C',
              onTap: () => _sendKey('\x03'),
            ),
            _buildKeyButton(
              label: '^D',
              onTap: () => _sendKey('\x04'),
            ),
            _buildKeyButton(
              label: '^Z',
              onTap: () => _sendKey('\x1a'),
            ),

            // Directional keys
            _buildKeyButton(
              label: '▲',
              onTap: () => _sendKey('\x1b[A'),
            ),
            _buildKeyButton(
              label: '▼',
              onTap: () => _sendKey('\x1b[B'),
            ),
            _buildKeyButton(
              label: '◄',
              onTap: () => _sendKey('\x1b[D'),
            ),
            _buildKeyButton(
              label: '►',
              onTap: () => _sendKey('\x1b[C'),
            ),

            // Common shell symbols
            _buildKeyButton(
              label: '|',
              onTap: () => _sendKey('|'),
            ),
            _buildKeyButton(
              label: '~',
              onTap: () => _sendKey('~'),
            ),
            _buildKeyButton(
              label: '/',
              onTap: () => _sendKey('/'),
            ),
            _buildKeyButton(
              label: '-',
              onTap: () => _sendKey('-'),
            ),
            _buildKeyButton(
              label: ':',
              onTap: () => _sendKey(':'),
            ),
          ],
        ),
      ),
    );
  }
}
