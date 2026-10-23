import 'package:dartssh2/dartssh2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/security/secure_storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/ssh_key_model.dart';

class KeyManagerScreen extends StatefulWidget {
  const KeyManagerScreen({super.key});

  @override
  State<KeyManagerScreen> createState() => _KeyManagerScreenState();
}

class _KeyManagerScreenState extends State<KeyManagerScreen> {
  List<SSHKeyMetadata> _keys = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    final keys = await AppDatabase.instance.getAllKeyMetadata();
    setState(() {
      _keys = keys;
      _isLoading = false;
    });
  }

  void _showAddKeyDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final pemController = TextEditingController();
    final passphraseController = TextEditingController();
    String? selectedFileName;
    bool isSaving = false;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Import SSH Private Key',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppTheme.textMuted),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Select a key file (.pem, id_ed25519, id_rsa) from your Downloads or paste the key contents manually.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 16),

                      // File Picker Button
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          try {
                            final file = await FilePicker.pickFile(
                              type: FileType.any,
                            );

                            if (file != null) {
                              final content = await file.xFile.readAsString();

                              if (content.trim().isNotEmpty) {
                                pemController.text = content.trim();
                                if (nameController.text.trim().isEmpty) {
                                  nameController.text = file.name
                                      .replaceAll('.pem', '')
                                      .replaceAll('.key', '')
                                      .replaceAll('.txt', '');
                                }
                                setSheetState(() {
                                  selectedFileName = file.name;
                                });
                              }
                            }
                          } catch (e) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('Error reading file: $e'),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.file_open_outlined, color: AppTheme.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedFileName == null
                                          ? 'Pick Key File from Downloads / Device'
                                          : 'Loaded: $selectedFileName',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: selectedFileName != null ? AppTheme.primary : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      selectedFileName == null
                                          ? 'Tap to select .pem, id_ed25519, or private key file'
                                          : 'File read successfully. Check details below.',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: AppTheme.primary, size: 20),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('OR PASTE KEY', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Key Name / Label',
                          hintText: 'e.g. id_ed25519_prod',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: pemController,
                        maxLines: 5,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        decoration: const InputDecoration(
                          labelText: 'Private Key PEM Content',
                          hintText: '-----BEGIN OPENSSH PRIVATE KEY-----\n...\n-----END OPENSSH PRIVATE KEY-----',
                          alignLabelWithHint: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'PEM content required';
                          if (!v.contains('PRIVATE KEY')) return 'Must contain valid PEM header';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: passphraseController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Passphrase (Optional)',
                          hintText: 'Leave empty if key has no passphrase',
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setSheetState(() => isSaving = true);

                                  final rawPem = pemController.text.trim();
                                  final passphrase = passphraseController.text.trim().isEmpty
                                      ? null
                                      : passphraseController.text.trim();

                                  // Validate parsing key
                                  String detectedType = 'ed25519';
                                  try {
                                    final pairs = SSHKeyPair.fromPem(rawPem, passphrase);
                                    if (pairs.isNotEmpty) {
                                      detectedType = pairs.first.type;
                                    }
                                  } catch (e) {
                                    setSheetState(() => isSaving = false);
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Invalid Key or Passphrase: $e'),
                                        backgroundColor: AppTheme.error,
                                      ),
                                    );
                                    return;
                                  }

                                  final alias = 'key_${const Uuid().v4().substring(0, 8)}';
                                  // Store in Keystore
                                  await SecureStorageService.instance.savePrivateKey(
                                    alias: alias,
                                    pem: rawPem,
                                    passphrase: passphrase,
                                  );

                                  // Store metadata in SQLite
                                  final meta = SSHKeyMetadata(
                                    alias: alias,
                                    name: nameController.text.trim(),
                                    keyType: detectedType,
                                    hasPassphrase: passphrase != null,
                                    createdAt: DateTime.now().millisecondsSinceEpoch,
                                  );
                                  await AppDatabase.instance.insertKeyMetadata(meta);

                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                  }
                                  if (mounted) {
                                    _loadKeys();
                                    scaffoldMessenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Key imported and secured in Keystore.'),
                                        backgroundColor: AppTheme.success,
                                      ),
                                    );
                                  }
                                },
                          child: isSaving
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Save & Encrypt Key'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteKey(SSHKeyMetadata key) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Key?'),
        content: Text('Are you sure you want to remove "${key.name}"? Any server profiles using this key will fail to authenticate.'),
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
      await SecureStorageService.instance.deleteKey(key.alias);
      await AppDatabase.instance.deleteKeyMetadata(key.alias);
      _loadKeys();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('SSH Key Manager'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: const Color(0xFF001E28),
        icon: const Icon(Icons.add),
        label: const Text('Import Key', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _showAddKeyDialog,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _keys.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.key_rounded, size: 48, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No SSH Keys Stored',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Select private key files from Downloads or paste them to authenticate securely without passwords.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showAddKeyDialog,
                          icon: const Icon(Icons.file_open_outlined),
                          label: const Text('Import from Downloads / Device'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: _keys.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final key = _keys[index];
                    final dateStr = DateFormat('MMM d, yyyy').format(DateTime.fromMillisecondsSinceEpoch(key.createdAt));

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.key_rounded, color: AppTheme.primary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  key.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceVariant,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        key.keyType.toUpperCase(),
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary),
                                      ),
                                    ),
                                    if (key.hasPassphrase) ...[
                                      const SizedBox(width: 6),
                                      const Icon(Icons.lock_rounded, size: 13, color: AppTheme.warning),
                                      const SizedBox(width: 2),
                                      const Text('Passphrase', style: TextStyle(fontSize: 11, color: AppTheme.warning)),
                                    ],
                                    const SizedBox(width: 8),
                                    Text('Added $dateStr', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                            onPressed: () => _deleteKey(key),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
