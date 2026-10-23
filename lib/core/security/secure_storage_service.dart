import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService instance = SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
    ),
  );

  SecureStorageService._internal();

  // Keys stored as: key_payload_{alias}
  Future<void> savePrivateKey({
    required String alias,
    required String pem,
    String? passphrase,
  }) async {
    await _storage.write(key: 'key_payload_$alias', value: pem);
    if (passphrase != null && passphrase.isNotEmpty) {
      await _storage.write(key: 'key_pass_$alias', value: passphrase);
    } else {
      await _storage.delete(key: 'key_pass_$alias');
    }
  }

  Future<String?> getPrivateKey(String alias) async {
    return await _storage.read(key: 'key_payload_$alias');
  }

  Future<String?> getKeyPassphrase(String alias) async {
    return await _storage.read(key: 'key_pass_$alias');
  }

  Future<void> deleteKey(String alias) async {
    await _storage.delete(key: 'key_payload_$alias');
    await _storage.delete(key: 'key_pass_$alias');
  }

  // Fallback: server password storage
  Future<void> saveServerPassword(String serverId, String password) async {
    await _storage.write(key: 'server_pwd_$serverId', value: password);
  }

  Future<String?> getServerPassword(String serverId) async {
    return await _storage.read(key: 'server_pwd_$serverId');
  }

  Future<void> deleteServerPassword(String serverId) async {
    await _storage.delete(key: 'server_pwd_$serverId');
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

