import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../models/known_host.dart';
import '../../models/server_profile.dart';
import '../../models/ssh_key_model.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _database;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'pocketops.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // PRD 7.1 Server Profile table
        await db.execute('''
          CREATE TABLE servers (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            host TEXT NOT NULL,
            port INTEGER NOT NULL DEFAULT 22,
            username TEXT NOT NULL,
            key_alias TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            last_connected_at INTEGER
          )
        ''');

        // PRD 7.2 Known Hosts table (for TOFU)
        await db.execute('''
          CREATE TABLE known_hosts (
            host TEXT NOT NULL,
            port INTEGER NOT NULL,
            key_type TEXT NOT NULL,
            fingerprint TEXT NOT NULL,
            first_seen_at INTEGER NOT NULL,
            PRIMARY KEY (host, port)
          )
        ''');

        // Key Metadata Table (Private keys are in FlutterSecureStorage)
        await db.execute('''
          CREATE TABLE ssh_keys (
            alias TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            key_type TEXT NOT NULL,
            has_passphrase INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // --- Servers CRUD ---
  Future<List<ServerProfile>> getAllServers() async {
    final db = await database;
    final maps = await db.query('servers', orderBy: 'name ASC');
    return maps.map((m) => ServerProfile.fromMap(m)).toList();
  }

  Future<List<ServerProfile>> getRecentServers({int limit = 5}) async {
    final db = await database;
    final maps = await db.query(
      'servers',
      where: 'last_connected_at IS NOT NULL',
      orderBy: 'last_connected_at DESC',
      limit: limit,
    );
    return maps.map((m) => ServerProfile.fromMap(m)).toList();
  }

  Future<void> insertServer(ServerProfile server) async {
    final db = await database;
    await db.insert(
      'servers',
      server.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateServer(ServerProfile server) async {
    final db = await database;
    await db.update(
      'servers',
      server.toMap(),
      where: 'id = ?',
      whereArgs: [server.id],
    );
  }

  Future<void> updateLastConnected(String serverId) async {
    final db = await database;
    await db.update(
      'servers',
      {'last_connected_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [serverId],
    );
  }

  Future<void> deleteServer(String id) async {
    final db = await database;
    await db.delete('servers', where: 'id = ?', whereArgs: [id]);
  }

  // --- Known Hosts (TOFU) ---
  Future<KnownHost?> getKnownHost(String host, int port) async {
    final db = await database;
    final results = await db.query(
      'known_hosts',
      where: 'host = ? AND port = ?',
      whereArgs: [host, port],
    );
    if (results.isNotEmpty) {
      return KnownHost.fromMap(results.first);
    }
    return null;
  }

  Future<void> saveKnownHost(KnownHost knownHost) async {
    final db = await database;
    await db.insert(
      'known_hosts',
      knownHost.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- SSH Keys Metadata ---
  Future<List<SSHKeyMetadata>> getAllKeyMetadata() async {
    final db = await database;
    final maps = await db.query('ssh_keys', orderBy: 'created_at DESC');
    return maps.map((m) => SSHKeyMetadata.fromMap(m)).toList();
  }

  Future<void> insertKeyMetadata(SSHKeyMetadata meta) async {
    final db = await database;
    await db.insert(
      'ssh_keys',
      meta.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteKeyMetadata(String alias) async {
    final db = await database;
    await db.delete('ssh_keys', where: 'alias = ?', whereArgs: [alias]);
  }
}

