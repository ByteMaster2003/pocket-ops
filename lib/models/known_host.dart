class KnownHost {
  final String host;
  final int port;
  final String keyType;
  final String fingerprint;
  final int firstSeenAt;

  const KnownHost({
    required this.host,
    required this.port,
    required this.keyType,
    required this.fingerprint,
    required this.firstSeenAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'host': host,
      'port': port,
      'key_type': keyType,
      'fingerprint': fingerprint,
      'first_seen_at': firstSeenAt,
    };
  }

  factory KnownHost.fromMap(Map<String, dynamic> map) {
    return KnownHost(
      host: map['host'] as String,
      port: (map['port'] as num).toInt(),
      keyType: map['key_type'] as String,
      fingerprint: map['fingerprint'] as String,
      firstSeenAt: (map['first_seen_at'] as num).toInt(),
    );
  }
}

