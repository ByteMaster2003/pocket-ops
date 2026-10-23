class ServerProfile {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String keyAlias;
  final int createdAt;
  final int? lastConnectedAt;

  const ServerProfile({
    required this.id,
    required this.name,
    required this.host,
    this.port = 22,
    required this.username,
    required this.keyAlias,
    required this.createdAt,
    this.lastConnectedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'key_alias': keyAlias,
      'created_at': createdAt,
      'last_connected_at': lastConnectedAt,
    };
  }

  factory ServerProfile.fromMap(Map<String, dynamic> map) {
    return ServerProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      host: map['host'] as String,
      port: (map['port'] as num?)?.toInt() ?? 22,
      username: map['username'] as String,
      keyAlias: (map['key_alias'] as String?) ?? '',
      createdAt: (map['created_at'] as num).toInt(),
      lastConnectedAt: (map['last_connected_at'] as num?)?.toInt(),
    );
  }

  ServerProfile copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? username,
    String? keyAlias,
    int? createdAt,
    int? lastConnectedAt,
  }) {
    return ServerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      keyAlias: keyAlias ?? this.keyAlias,
      createdAt: createdAt ?? this.createdAt,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
    );
  }
}

