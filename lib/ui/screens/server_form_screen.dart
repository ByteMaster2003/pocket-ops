import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/security/secure_storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/server_profile.dart';
import '../../models/ssh_key_model.dart';
import 'key_manager_screen.dart';

class ServerFormScreen extends StatefulWidget {
  final ServerProfile? serverToEdit;

  const ServerFormScreen({super.key, this.serverToEdit});

  @override
  State<ServerFormScreen> createState() => _ServerFormScreenState();
}

class _ServerFormScreenState extends State<ServerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  String _authMethod = 'key'; // 'key' or 'password'
  String? _selectedKeyAlias;
  List<SSHKeyMetadata> _availableKeys = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final s = widget.serverToEdit;
    _nameController = TextEditingController(text: s?.name ?? '');
    _hostController = TextEditingController(text: s?.host ?? '');
    _portController = TextEditingController(text: (s?.port ?? 22).toString());
    _usernameController = TextEditingController(text: s?.username ?? '');
    _passwordController = TextEditingController();

    if (s != null) {
      if (s.keyAlias.isNotEmpty && s.keyAlias != 'password') {
        _authMethod = 'key';
        _selectedKeyAlias = s.keyAlias;
      } else {
        _authMethod = 'password';
      }
    }

    _loadKeysAndData();
  }

  Future<void> _loadKeysAndData() async {
    final keys = await AppDatabase.instance.getAllKeyMetadata();

    // If editing and password was used, load it
    if (widget.serverToEdit != null && _authMethod == 'password') {
      final pwd = await SecureStorageService.instance.getServerPassword(widget.serverToEdit!.id);
      if (pwd != null) {
        _passwordController.text = pwd;
      }
    }

    setState(() {
      _availableKeys = keys;
      if (_selectedKeyAlias == null && keys.isNotEmpty && _authMethod == 'key') {
        _selectedKeyAlias = keys.first.alias;
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveServer() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 22;
    final username = _usernameController.text.trim();

    final isNew = widget.serverToEdit == null;
    final serverId = isNew ? const Uuid().v4() : widget.serverToEdit!.id;
    final keyAlias = _authMethod == 'key' ? (_selectedKeyAlias ?? '') : 'password';

    final profile = ServerProfile(
      id: serverId,
      name: name,
      host: host,
      port: port,
      username: username,
      keyAlias: keyAlias,
      createdAt: widget.serverToEdit?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
      lastConnectedAt: widget.serverToEdit?.lastConnectedAt,
    );

    if (_authMethod == 'password' && _passwordController.text.isNotEmpty) {
      await SecureStorageService.instance.saveServerPassword(serverId, _passwordController.text);
    }

    if (isNew) {
      await AppDatabase.instance.insertServer(profile);
    } else {
      await AppDatabase.instance.updateServer(profile);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.serverToEdit != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Server Profile' : 'New Server Profile'),
        actions: [
          TextButton(
            onPressed: _saveServer,
            child: const Text('Save', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section: Connection Details
                    const Text(
                      'CONNECTION DETAILS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Profile Label',
                        hintText: 'e.g. AWS Production EC2',
                        prefixIcon: Icon(Icons.label_outline, color: AppTheme.textMuted),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Label is required' : null,
                    ),
                    const SizedBox(height: 14),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _hostController,
                            decoration: const InputDecoration(
                              labelText: 'Host / IP Address',
                              hintText: '192.168.1.1 or example.com',
                              prefixIcon: Icon(Icons.language_rounded, color: AppTheme.textMuted),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Host is required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _portController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Port',
                              hintText: '22',
                            ),
                            validator: (val) {
                              final p = int.tryParse(val ?? '');
                              if (p == null || p <= 0 || p > 65535) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        hintText: 'ubuntu, root, ec2-user',
                        prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Username is required' : null,
                    ),

                    const SizedBox(height: 28),

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

                    // Segmented Selector for Auth Type
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              setState(() {
                                _authMethod = 'key';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _authMethod == 'key' ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.surfaceVariant.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _authMethod == 'key' ? AppTheme.primary : AppTheme.border,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.key_rounded, size: 18, color: _authMethod == 'key' ? AppTheme.primary : AppTheme.textMuted),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Private Key',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: _authMethod == 'key' ? AppTheme.primary : AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              setState(() {
                                _authMethod = 'password';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _authMethod == 'password' ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.surfaceVariant.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _authMethod == 'password' ? AppTheme.primary : AppTheme.border,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.password_rounded, size: 18, color: _authMethod == 'password' ? AppTheme.primary : AppTheme.textMuted),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Password',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: _authMethod == 'password' ? AppTheme.primary : AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (_authMethod == 'key') ...[
                      if (_availableKeys.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'No SSH Keys Imported',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Import or generate an Ed25519 or RSA key stored safely in your phone\'s Hardware Keystore.',
                                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Private Key'),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const KeyManagerScreen()),
                                  );
                                  _loadKeysAndData();
                                },
                              ),
                            ],
                          ),
                        )
                      else ...[
                        DropdownButtonFormField<String>(
                          initialValue: _selectedKeyAlias,
                          decoration: const InputDecoration(
                            labelText: 'Select Private Key',
                            prefixIcon: Icon(Icons.vpn_key_outlined, color: AppTheme.textMuted),
                          ),
                          dropdownColor: AppTheme.surface,
                          items: _availableKeys.map((k) {
                            return DropdownMenuItem(
                              value: k.alias,
                              child: Text(
                                '${k.name} (${k.keyType.toUpperCase()})',
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedKeyAlias = val;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.vpn_key, size: 16, color: AppTheme.primary),
                            label: const Text('Manage Keys', style: TextStyle(color: AppTheme.primary, fontSize: 13)),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const KeyManagerScreen()),
                              );
                              _loadKeysAndData();
                            },
                          ),
                        ),
                      ],
                    ] else ...[
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter SSH password',
                          prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textMuted),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Stored securely in Android Keystore / EncryptedSharedPreferences.',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveServer,
                        child: Text(isEditing ? 'Update Server Profile' : 'Save Server Profile'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
