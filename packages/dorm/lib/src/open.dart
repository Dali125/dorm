import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dorm.dart';
import 'logger.dart';

/// Database driver opener for SQLite / Flutter / Desktop / Tests.
class DormOpenOptions {
  final int version;
  final bool enableForeignKeys;
  final DormLogger? logger;

  const DormOpenOptions({
    this.version = 1,
    this.enableForeignKeys = true,
    this.logger,
  });
}

/// Backwards compatibility alias for [DormOpenOptions].
typedef GormOpenOptions = DormOpenOptions;

/// Helper to initialize and open SQLite databases via DORM.
class Dorm {
  /// Opens a SQLite database at [path] and returns an initialized [DormDB].
  static Future<DormDB> open(
    String path, {
    DormOpenOptions options = const DormOpenOptions(),
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

    return DormDB(db, logger: options.logger);
  }

  /// Opens an in-memory SQLite database, ideal for testing and rapid prototyping.
  static Future<DormDB> openInMemory({
    DormOpenOptions options = const DormOpenOptions(),
  }) async {
    sqfliteFfiInit();
    return open(
      inMemoryDatabasePath,
      options: options,
      databaseFactory: databaseFactoryFfi,
    );
  }
}

/// Backwards compatibility alias for [Dorm].
typedef Gorm = Dorm;

