import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'relic.dart';
import 'logger.dart';

/// Database driver opener for SQLite / Flutter / Desktop / Tests.
class RelicOpenOptions {
  final int version;
  final bool enableForeignKeys;
  final RelicLogger? logger;

  const RelicOpenOptions({
    this.version = 1,
    this.enableForeignKeys = true,
    this.logger,
  });
}

/// Backwards compatibility alias for [RelicOpenOptions].
typedef GormOpenOptions = RelicOpenOptions;

/// Helper to initialize and open SQLite databases via RELIC.
class Relic {
  /// Opens a SQLite database at [path] and returns an initialized [RelicDB].
  static Future<RelicDB> open(
    String path, {
    RelicOpenOptions options = const RelicOpenOptions(),
    DatabaseFactory? databaseFactory,
  }) async {
    final factory = databaseFactory ?? databaseFactoryFfi;
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: options.version,
        onConfigure: (db) async {
          if (options.enableForeignKeys) {
            await db.execute('PRAGMA foreign_keys = ON;');
          }
        },
      ),
    );

    return RelicDB(db, logger: options.logger);
  }

  /// Opens an in-memory SQLite database, ideal for testing and rapid prototyping.
  static Future<RelicDB> openInMemory({
    RelicOpenOptions options = const RelicOpenOptions(),
  }) async {
    sqfliteFfiInit();
    return open(
      inMemoryDatabasePath,
      options: options,
      databaseFactory: databaseFactoryFfi,
    );
  }
}

/// Backwards compatibility alias for [Relic].
typedef Gorm = Relic;

