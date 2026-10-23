import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import '../database/app_database.dart';
import 'secure_storage_service.dart';

class AppLockService {
  static final AppLockService instance = AppLockService._internal();
  final LocalAuthentication _localAuth = LocalAuthentication();

  AppLockService._internal();

  static const String _keyMpinHash = 'app_mpin_hash';
  static const String _keyMpinSalt = 'app_mpin_salt';
  static const String _keyBiometricEnabled = 'app_biometric_enabled';

  // Check if initial setup has been completed
  Future<bool> isMpinSet() async {
    final hash = await SecureStorageService.instance.getPrivateKey(_keyMpinHash);
    return hash != null && hash.isNotEmpty;
  }

  // Check if fingerprint unlock is enabled
  Future<bool> isBiometricEnabled() async {
    final val = await SecureStorageService.instance.getPrivateKey(_keyBiometricEnabled);
    return val == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await SecureStorageService.instance.savePrivateKey(
      alias: _keyBiometricEnabled,
      pem: enabled ? 'true' : 'false',
    );
  }

  // Check if device supports fingerprint hardware
  Future<bool> isFingerprintAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      if (!canAuthenticate) return false;

      final available = await _localAuth.getAvailableBiometrics();
      return available.contains(BiometricType.fingerprint) ||
          available.contains(BiometricType.strong);
    } catch (_) {
      return false;
    }
  }

  // Prompt fingerprint authentication
  Future<bool> authenticateWithFingerprint() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint to unlock PocketOps',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  // Set new MPIN with secure random salt + SHA-256
  Future<void> setMpin(String mpin) async {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    final salt = base64.encode(saltBytes);
    final hash = _hashMpin(mpin, salt);

    await SecureStorageService.instance.savePrivateKey(alias: _keyMpinSalt, pem: salt);
    await SecureStorageService.instance.savePrivateKey(alias: _keyMpinHash, pem: hash);
  }

  // Verify entered MPIN against stored hash
  Future<bool> verifyMpin(String mpin) async {
    final salt = await SecureStorageService.instance.getPrivateKey(_keyMpinSalt);
    final expectedHash = await SecureStorageService.instance.getPrivateKey(_keyMpinHash);

    if (salt == null || expectedHash == null) return false;
    final enteredHash = _hashMpin(mpin, salt);
    return enteredHash == expectedHash;
  }

  // Reset MPIN after successful login
  Future<bool> changeMpin({required String oldMpin, required String newMpin}) async {
    final isValid = await verifyMpin(oldMpin);
    if (!isValid) return false;
    await setMpin(newMpin);
    return true;
  }

  // Wipe everything locally: no second chance
  Future<void> wipeAllData() async {
    // 1. Wipe SQLite
    final db = await AppDatabase.instance.database;
    await db.delete('servers');
    await db.delete('known_hosts');
    await db.delete('ssh_keys');

    // 2. Clear all keys from SecureStorage
    await SecureStorageService.instance.clearAll();
  }

  String _hashMpin(String mpin, String salt) {
    final bytes = utf8.encode('$salt:$mpin:pocketops_secure');
    return sha256.convert(bytes).toString();
  }
}
