import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../database/app_database.dart';
import '../../models/known_host.dart';

enum TofuVerificationResult {
  trusted,
  newHostPromptRequired,
  mismatchRejected,
}

class TofuVerificationResponse {
  final TofuVerificationResult result;
  final String keyType;
  final String fingerprint;
  final String? existingFingerprint;

  const TofuVerificationResponse({
    required this.result,
    required this.keyType,
    required this.fingerprint,
    this.existingFingerprint,
  });
}

class TofuService {
  static String calculateFingerprint(List<int> rawKeyBytes) {
    final digest = sha256.convert(rawKeyBytes);
    return 'SHA256:${base64.encode(digest.bytes).replaceAll('=', '')}';
  }

  static Future<TofuVerificationResponse> verifyHost({
    required String host,
    required int port,
    required String keyType,
    required List<int> rawKeyBytes,
  }) async {
    final fingerprint = calculateFingerprint(rawKeyBytes);
    final knownHost = await AppDatabase.instance.getKnownHost(host, port);

    if (knownHost == null) {
      return TofuVerificationResponse(
        result: TofuVerificationResult.newHostPromptRequired,
        keyType: keyType,
        fingerprint: fingerprint,
      );
    }

    if (knownHost.fingerprint == fingerprint) {
      return TofuVerificationResponse(
        result: TofuVerificationResult.trusted,
        keyType: keyType,
        fingerprint: fingerprint,
      );
    } else {
      return TofuVerificationResponse(
        result: TofuVerificationResult.mismatchRejected,
        keyType: keyType,
        fingerprint: fingerprint,
        existingFingerprint: knownHost.fingerprint,
      );
    }
  }

  static Future<void> pinHostKey({
    required String host,
    required int port,
    required String keyType,
    required String fingerprint,
  }) async {
    await AppDatabase.instance.saveKnownHost(
      KnownHost(
        host: host,
        port: port,
        keyType: keyType,
        fingerprint: fingerprint,
        firstSeenAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}

