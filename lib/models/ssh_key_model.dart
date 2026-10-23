class SSHKeyMetadata {
  final String alias;
  final String name;
  final String keyType;
  final bool hasPassphrase;
  final int createdAt;

  const SSHKeyMetadata({
    required this.alias,
    required this.name,
    required this.keyType,
    this.hasPassphrase = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'alias': alias,
      'name': name,
      'key_type': keyType,
      'has_passphrase': hasPassphrase ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory SSHKeyMetadata.fromMap(Map<String, dynamic> map) {
    return SSHKeyMetadata(
      alias: map['alias'] as String,
      name: map['name'] as String,
      keyType: map['key_type'] as String,
      hasPassphrase: (map['has_passphrase'] as int?) == 1,
      createdAt: (map['created_at'] as num).toInt(),
    );
  }
}

